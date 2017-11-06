pragma solidity ^ 0.4.11;


contract SafeMath {
    function safeMul(uint a, uint b) internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns(uint) {
        assert(b > 0);
        
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns(uint) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint a, uint b) internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

}


contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) constant returns(uint);

    function allowance(address owner, address spender) constant returns(uint);

    function transfer(address to, uint value) returns(bool ok);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) 
            owner = newOwner;
    }

    function kill() {
        if (msg.sender == owner) 
            selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
        _;
    }
}


contract Pausable is Ownable {
    bool public stopped;

    event StoppedInEmergency(bool stopped);
    event StartedFromEmergency(bool started);

    modifier stopInEmergency {
        if (stopped) {
            revert();
        }
        _;
    }

    modifier onlyInEmergency {
        if (!stopped) {
            revert();
        }
        _;
    }

    // Called by the owner in emergency, triggers stopped state
    function emergencyStop() external onlyOwner {
        stopped = true;
        StoppedInEmergency(true);
    }

    // Called by the owner to end of emergency, returns to normal state
    function release() external onlyOwner onlyInEmergency {
        stopped = false;
        StartedFromEmergency(true);
    }
}



// Base contract supporting async send for pull payments.
// Inherit from this contract and use asyncSend instead of send.
contract PullPayment {
    mapping(address => uint) public payments;

    event RefundETH(address to, uint value);

    // Store sent amount as credit to be pulled, called by payer

    function asyncSend(address dest, uint amount) internal {

        payments[dest] += amount;
    }
    // TODO: check
    // Withdraw accumulated balance, called by payee
    function withdrawPayments() internal returns (bool) {
        address payee = msg.sender;
        uint payment = payments[payee];

        if (payment == 0) {
            revert();
        }

        if (this.balance < payment) {
            revert();
        }

        payments[payee] = 0;

        if (!payee.send(payment)) {
            revert();
        }
        RefundETH(payee, payment);
        return true;
    }
}


// Crowdsale Smart Contract
// This smart contract collects ETH and in return sends  tokens to the Backers
contract Crowdsale is SafeMath, Pausable, PullPayment {

    struct Backer {
        uint weiReceived; // amount of ETH contributed
        uint tokensSent; // amount of tokens  sent        
    }

    Token public token; // Token contract reference   
    address public multisigETH; // Multisig contract that will receive the ETH         
    uint public tokensForTeam; // Amount of tokens to be allocated to team if campaign succeeds
    uint public ETHReceived; // Number of ETH received
    uint public tokensSentToETH; // Number of tokens sent to ETH contributors
    uint public startBlock; // Crowdsale start block
    uint public endBlock; // Crowdsale end block
    uint public maxCap; // Maximum number of token to sell
    uint public minCap; // Minimum number of ETH to raise
    uint public minContributionETH; // Minimum amount to invest
    bool public crowdsaleClosed; // Is crowdsale still on going
    uint public tokenPriceWei;
    uint public campaignDurationDays; // campaign duration in days 
    uint firstPeriod; 
    uint secondPeriod; 
    uint thirdPeriod; 
    uint firstBonus; 
    uint secondBonus;
    uint thirdBonus;
    uint public multiplier;

    
   
    // Looping through Backer
    mapping(address => Backer) public backers; //backer list
    address[] public backersIndex ;   // to be able to itarate through backers when distributing the tokens. 


    // @notice to verify if action is not performed out of the campaing range
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }

    modifier minCapNotReached() {
        if (tokensSentToETH >= minCap) 
            revert();
        _;
    }

    // Events
    event ReceivedETH(address backer, uint amount, uint tokenAmount);
    event Started(uint startBlock, uint endBlock);
    event Finalized(bool success);

    // Crowdsale  {constructor}
    // @notice fired when contract is crated. Initilizes all constnat variables.

    function Crowdsale(uint _decimalPoints,
                        address _multisigETH,                       
                        uint _toekensForTeam, 
                        uint _minContributionETH,
                        uint _maxCap, 
                        uint _minCap, 
                        uint _tokenPriceWei, 
                        uint _campaignDurationDays,
                        uint _firstPeriod, 
                        uint _secondPeriod, 
                        uint _thirdPeriod, 
                        uint _firstBonus, 
                        uint _secondBonus,
                        uint _thirdBonus) {
    
        multiplier = 10**_decimalPoints;
        multisigETH = _multisigETH; //TODO: Replace address with correct one       
        tokensForTeam = _toekensForTeam * multiplier;                          
        minContributionETH = _minContributionETH; // 0.1 eth
        startBlock = 0; // ICO start block
        endBlock = 0; // ICO end block            
        maxCap = _maxCap * multiplier;        
        tokenPriceWei = _tokenPriceWei;
        minCap = _minCap * multiplier;
        campaignDurationDays = _campaignDurationDays;
        firstPeriod = _firstPeriod; 
        secondPeriod = _secondPeriod; 
        thirdPeriod = _thirdPeriod;
        firstBonus = _firstBonus;
        secondBonus = _secondBonus;
        thirdBonus = _thirdBonus; 
               
    }

    // @notice Specify address of token contract
    // @param _tokenAddress {address} address of token contract
    // @return res {bool}

    function updateTokenAddressAndOwner(Token _tokenAddress, address _newOwner) public onlyOwner() returns(bool res) {
        token = _tokenAddress;  
        owner = _newOwner;
        return true;    
    }



    // @notice return number of contributors
    // @return  {uint} number of contributors

    function numberOfBackers()constant returns (uint) {
        return backersIndex.length;
    }

    // {fallback function}
    // @notice It will call internal function which handels allocation of Ether and calculates tokens.
    function () payable {         
        handleETH(msg.sender);
    }

    // @notice It will be called by owner to start the sale    
    function start() onlyOwner() {
        startBlock = block.number;
        endBlock = startBlock + (4*60*24*campaignDurationDays); // assumption is that one block takes 15 sec. 
        crowdsaleClosed = false;
        Started(startBlock, endBlock);
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _backer {address} address of beneficiary
    // @return res {bool} true if transaction was successful
    function handleETH(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {

        if (msg.value < minContributionETH) 
            revert(); // stop when required minimum is not sent

        uint tokensToSend = calculateNoOfTokensToSend(); // calculate number of tokens

        // Ensure that max cap hasn't been reached
        if (safeAdd(tokensSentToETH, tokensToSend) > maxCap) 
            revert();

        Backer storage backer = backers[_backer];

         if ( backer.weiReceived == 0)
             backersIndex.push(_backer);

        if (!token.transfer(_backer, tokensToSend)) 
            revert(); // Transfer tokens to contributor
        backer.tokensSent = safeAdd(backer.tokensSent, tokensToSend);
        backer.weiReceived = safeAdd(backer.weiReceived, msg.value);
        ETHReceived = safeAdd(ETHReceived, msg.value); // Update the total Ether recived
        tokensSentToETH = safeAdd(tokensSentToETH, tokensToSend);

       
        

        ReceivedETH(_backer, msg.value, tokensToSend); // Register event
        return true;
    }

    // @notice This function will return number of tokens based on time intervals in the campaign
    function calculateNoOfTokensToSend() constant internal returns (uint) {

        uint tokenAmount = safeDiv(safeMul(msg.value, multiplier), tokenPriceWei);
        

        if (block.number <= startBlock + firstPeriod )  
            return  tokenAmount + safeDiv(safeMul(tokenAmount, firstBonus), 100);
        else if (block.number <= startBlock + secondPeriod)
            return  tokenAmount + safeDiv(safeMul(tokenAmount, secondBonus), 100); 
        else if (block.number <= startBlock + thirdPeriod) 
                return  tokenAmount + safeDiv(safeMul(tokenAmount, thirdBonus), 100);        
        else         
            return  tokenAmount; 
    }

    // @notice This function will finalize the sale.
    // It will only execute if predetermined sale time passed or all tokens are sold.
    function finalize() onlyOwner() {

        if (crowdsaleClosed) 
            revert();

        //TODO uncomment this for live
        //uint daysToRefund = 4*60*24*15;
        uint daysToRefund = 3;  

        if (block.number < endBlock && tokensSentToETH < maxCap - 100 ) 
        revert();   // - 100 is used to allow closing of the campaing when contribution is near 
                    // finished as exact amount of maxCap might be not feasible e.g. you can't easily buy few tokens. 
                    // when min contribution is 0.1 Eth.  

        if (tokensSentToETH < minCap && block.number < safeAdd(endBlock, daysToRefund)) 
            revert();   

        if (tokensSentToETH > minCap) {
            if (!multisigETH.send(this.balance)) 
            revert();  // transfer balance to multisig wallet
            if (!token.transfer(multisigETH, token.balanceOf(this))) 
            revert(); // transfer tokens to admin account or multisig wallet                                
            token.unlock();    // release lock from transfering tokens. 
        }else {
            if (!token.burn(this, token.balanceOf(this))) 
            revert();  // burn all the tokens remaining in the contract                      
        }

        crowdsaleClosed = true;
        Finalized(true);
        
    }



    // TODO do we want this here?
    // @notice Failsafe drain
    function drain() onlyOwner() {
        if (!owner.send(this.balance)) 
            revert();
    }

    // @notice Prepare refund of the backer if minimum is not reached
    // burn the tokens
    function prepareRefund()  minCapNotReached internal returns (bool){
        uint value = backers[msg.sender].tokensSent;

        if (value == 0) 
            revert();           
        if (!token.burn(msg.sender, value)) 
            revert();
        uint ETHToSend = backers[msg.sender].weiReceived;
        backers[msg.sender].weiReceived = 0;
        backers[msg.sender].tokensSent = 0;
        if (ETHToSend > 0) {
            asyncSend(msg.sender, ETHToSend);
            return true;
        } else 

            return false;
        
    }

    // @notice refund the backer
    function refund() public returns (bool){

        if (!prepareRefund()) 
            revert();
        if (!withdrawPayments()) 
            revert();
        return true;

    }

 
}

// The  token
contract Token is ERC20, SafeMath, Ownable {
    // Public variables of the token
    string public name;
    string public symbol;
    uint public decimals; // How many decimals to show.
    string public version = "v0.1";
    uint public totalSupply;
    bool public locked;
    address public crowdSaleAddress;
           


    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    

    // Lock transfer during the ICO
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && locked && msg.sender != owner) 
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if ( msg.sender != crowdSaleAddress && msg.sender != owner) 
            revert();
        _;
    }

    // The Token constructor

     
    function Token(uint _initialSupply,
            string _tokenName,
            uint _decimalUnits,
            string _tokenSymbol,
            string _version,
            address _crowdSaleAddress,
            address _owner) {      
        locked = true;  // Lock the transfer of tokens during the crowdsale
        totalSupply = _initialSupply * (10**_decimalUnits);     
                                        
        name = _tokenName; // Set the name for display purposes
        symbol = _tokenSymbol; // Set the symbol for display purposes
        decimals = _decimalUnits; // Amount of decimals for display purposes
        version = _version;
        crowdSaleAddress = _crowdSaleAddress;       
        balances[crowdSaleAddress] = totalSupply;
        owner = _owner;
       
    }


    

    function resetCrowdSaleAddress(address _newCrowdSaleAddress) onlyAuthorized() {
            crowdSaleAddress = _newCrowdSaleAddress;
    }

    

    function unlock() onlyAuthorized {
        locked = false;
    }

      function lock() onlyAuthorized {
        locked = true;
    }

    function burn( address _member, uint256 _value) onlyAuthorized returns(bool) {
        balances[_member] = safeSub(balances[_member], _value);
        totalSupply = safeSub(totalSupply, _value);
        Transfer(_member, 0x0, _value);
        return true;
    }

    function transfer(address _to, uint _value) onlyUnlocked returns(bool) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) onlyUnlocked returns(bool success) {
        if (balances[_from] < _value) 
            revert(); // Check if the sender has enough
        if (_value > allowed[_from][msg.sender]) 
            revert(); // Check allowance
        balances[_from] = safeSub(balances[_from], _value); // Subtract from the sender
        balances[_to] = safeAdd(balances[_to], _value); // Add the same to the recipient
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns(uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns(uint remaining) {
        return allowed[_owner][_spender];
    }
}
