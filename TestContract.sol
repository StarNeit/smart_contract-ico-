pragma solidity ^0.4.0;

contract TestContract {
    struct coiner {
        address addr;
        string tokenName;
        string description;
        string tickerSymbol;
    }

    coiner owner;

    function TestContract(address _addr, string _tn, string _desc, string _ts) {
        owner.addr = _addr;
        owner.tokenName = _tn;
        owner.description = _desc;
        owner.tickerSymbol = _ts;
    }

    function setOwnerAddr(address _addr) {
        owner.addr = _addr;
    }

    function getOwnerAddr() returns(address) {
        return owner.addr;
    }

    function setTokenName(string _tokenName) {
        owner.tokenName = _tokenName;
    }

    function getTokenName() returns(string) {
        return owner.tokenName;
    }

    function setDescription(string _desc) {
        owner.description = _desc;
    }

    function getDescription() returns(string) {
        return owner.description;
    }

    function setTickerSymbol(string _tickerSymbol) {
        owner.tickerSymbol = _tickerSymbol;
    }

    function getTickerSymbol() returns(string) {
        return owner.tickerSymbol;
    }
}