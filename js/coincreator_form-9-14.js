$(document).ready(function () {

    //var account, publicTokenName, tokenSymbol, tokenVersion, capped, initialSupply, decimalPoints;

    var form = $('#jsonForm');


    function checkRequiredFields(){

        var content = '';
        form.find(".required").each(function(){

            if($(this).val()==''){
                if(!$(this).hasClass('error-block'))
                    $(this).addClass('error-block');
                if($(this).attr('id').substring(0,3)!='sum')
                    content = content + "<p style='font-size: 20px; color:red'>"+$(this).attr('placeholder')+"  Invalid </p>"

            }else{
                if($(this).hasClass('error-block'))
                    $(this).removeClass('error-block');
            }
        });

        return content;
    }

    $(".required").on("change",function(){

        if($(this).val()!=''){
            if($(this).hasClass('error-block'))
                $(this).removeClass('error-block');
            var sum ="sum_"+$(this).attr('id');
            if($("#"+sum).hasClass('error-block'))
                $("#"+sum).removeClass('error-block');

        }else{
            if(!$(this).hasClass('error-block'))
                $(this).addClass('error-block');
            var sum ="sum_"+$(this).attr('id');
            if(!$("#"+sum).hasClass('error-block'))
                $("#"+sum).addClass('error-block');

        }
    });

    $('#btnSaveChanges').on('click', function () {

      /*  if(checkRequiredFields()!=''){
            $("#validation-content").html(checkRequiredFields());
            $("#validation-modal").modal('show');

            return 0;
        }
        */

        var account = $("#beneficiaryAddress").val();
        var publicTokenName = $("#tokenName").val();
        var tokenSymbol = $("#symbol").val();
        var tokenVersion = $("#tokenVersion").val();
        var capped = $('#isDecimalPoint').prop("checked") ? "on" : "off";
        var initialSupply = $("#initialSupply").val();
        var decimalPoints = $("#numberOfDecimalPoints").val();

        var multisigETH = $("#multiSigEth").val();
        var tokensForTeam = $("#tokensForTeam").val();
        var minContributionETH = $("#minContributionEth").val();
        var maxCap = $("#maxCap").val();
        var minCap = $("#minCap").val();
        var tokenPriceWei = $("#tokenPriceWei").val();
        var campaignDurationDays =  $("#campaignDurationDays").val();
        var firstPeriod = $("#firstPeriod").val();
        var secondPeriod = $("#secondPeriod").val();
        var thirdPeriod =  $("#thirdPeriod").val();
        var firstBonus = $("#firstBonus").val();
        var secondBonus = $("#secondBonus").val();
        var thirdBonus = $("#thirdBonus").val();

        $("#loading").addClass("loading");

        $.post("https://node3.coinlaunch.co/" + "compile_deploy", {
            initialSupply:initialSupply,
            tokenName:publicTokenName,
            decimalUnits:decimalPoints,
            tokenSymbol:tokenSymbol,
            tokenVersion:tokenVersion,
            multisigETH: multisigETH,
            tokensForTeam: tokensForTeam,
            minContributionETH: minContributionETH,
            maxCap: maxCap,
            minCap: minCap,
            tokenPriceWei: tokenPriceWei,
            campaignDurationDays: campaignDurationDays,
            firstPeriod: firstPeriod,
            secondPeriod: secondPeriod,
            thirdPeriod: thirdPeriod,
            firstBonus: firstBonus,
            secondBonus: secondBonus,
            thirddBonus: thirdBonus
        })
            .done(
                function (data, status) {

                    $.cookie("account",account);
                    $.cookie("publicTokenName",publicTokenName);
                    $.cookie("tokenSymbol",tokenSymbol);
                    $.cookie("tokenVersion",tokenVersion);
                    $.cookie("capped",capped);
                    $.cookie("initialSupply",initialSupply);
                    $.cookie("decimalPoints",decimalPoints);

                    $.cookie("multisigETH",multisigETH);
                    $.cookie("tokensForTeam",tokensForTeam);
                    $.cookie("minContributionETH",minContributionETH);
                    $.cookie("maxCap",maxCap);
                    $.cookie("minCap",minCap);
                    $.cookie("tokenPriceWei",tokenPriceWei);
                    $.cookie("campaignDurationDays",campaignDurationDays);
                    $.cookie("firstPeriod",firstPeriod);
                    $.cookie("secondPeriod",secondPeriod);
                    $.cookie("thirdPeriod",thirdPeriod);
                    $.cookie("firstBonus",firstBonus);
                    $.cookie("secondBonus",secondBonus);
                    $.cookie("thirdBonus",thirdBonus);

                    $("#loading").removeClass("loading");

                    if (data != "" && status == "success") {

                        var myObj = JSON.parse(data);
                        $("#result").html("Token contract has been deployed at this address: <a href='http://ropsten.etherscan.io/address/" +
                            myObj.tokenAddress + "' onclick=\"window.open(this.href, 'mywin','left=20,top=20,width=1024,height=768,toolbar=1,resizable=0'); return false;\">http://ropsten.etherscan.io/address/" + myObj.tokenAddress + "</a><br>" +
                            "Crowdsale contract has been deployed at this address: <a href=http://ropsten.etherscan.io/address/" +
                            myObj.crowdsaleAddress + "' onclick=\"window.open(this.href, 'mywin','left=20,top=20,width=1024,height=768,toolbar=1,resizable=0'); return false;\">http://ropsten.etherscan.io/address/" + myObj.crowdsaleAddress + "</a>" );


                        $("#complete-modal").modal('show');
                    }
                }
            )
            .fail(
                function(xhr, status, error) {
                    $("#loading").removeClass("loading");
                    $("#error-modal").modal('show');
                }
            );
    });

    $("#btnStartICO").click(function () {
      //  startICO();
    });


    $("#btnEmergencyStop").click(function () {
      //  stopInEmergency();
    });

    $("#btnEmergencyRestart").click(function () {
      //  restartFromEmergency();
    });

    $("#btnFinalize").click(function () {
       // finalize();
    });

    $('#tab_summary').on('click',function(){

        $("#sum_beneficiaryAddress").val($("#beneficiaryAddress").val());
        $("#sum_tokenName").val($("#tokenName").val());
        $("#sum_symbol").val($("#symbol").val());
        $("#sum_tokenVersion").val($("#tokenVersion").val());

        $('#sum_isDecimalPoint').prop("checked",$('#isDecimalPoint').prop("checked"));

        $("#sum_initialSupply").val($("#initialSupply").val());
        $("#sum_numberOfDecimalPoints").val($("#numberOfDecimalPoints").val());
        $("#sum_multiSigEth").val($("#multiSigEth").val());
        $("#sum_tokensForTeam").val($("#tokensForTeam").val());
        $("#sum_minContributionEth").val($("#minContributionEth").val());
        $("#sum_maxCap").val($("#maxCap").val());
        $("#sum_minCap").val($("#minCap").val());
        $("#sum_tokenPriceWei").val($("#tokenPriceWei").val());
        $("#sum_campaignDurationDays").val($("#campaignDurationDays").val());
        $("#sum_firstPeriod").val($("#firstPeriod").val());
        $("#sum_secondPeriod").val($("#secondPeriod").val());
        $("#sum_thirdPeriod").val($("#thirdPeriod").val());
        $("#sum_firstBonus").val($("#firstBonus").val());
        $("#sum_secondBonus").val($("#secondBonus").val());
        $("#sum_thirdBonus").val($("#thirdBonus").val());
        $("#sum_percentageFee").val($("#percentageFee").val());


    });

    $("#btn_reset").on("click",function(){
        form.find("input").val("");

        $('#sum_isDecimalPoint').prop("checked",false);
        $('#isDecimalPoint').prop("checked",false);
        $('#description').val('');

        form.find(".required").each(function(){

            if($(this).hasClass('error-block'))
                $(this).removeClass('error-block');
        });

    });

    $("#terms_content").on("scroll",function(){

        if($(this).scrollTop()>=($(this).get(0).scrollHeight-$(this).height()-100)){
            $("#btnSaveChanges").prop("disabled","");
       }
    });
});