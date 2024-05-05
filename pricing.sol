//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import

contract Price {
    // mint price and limit per wallet
    uint256 public _mintPrice;
    uint256 public _mintLimit;

    // fee charges for per mint or you can say the platoform fee data;
    uint256 public feePercent = 5;
    uint256 public percentDecimal = 10;

    function setMintPrice(uint256 _price, uint256 _limit) internal {
        _mintPrice = _price;
        _mintLimit = _limit;
    }

    function setFeeCharges(uint256 _percent, uint256 _decimal) internal {
        feePercent = _percent;
        percentDecimal = _decimal;
    }

    function encodedData(uint256 _price, uint256 _limit, uint256 _feePercent, uint256 _percentDecimal)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_price, _limit, _feePercent, _percentDecimal);
    }

    function distributeFunds(
        address payable recipient1,
        address payable recipient2
    ) public payable {
        if (_mintPrice > 0) {
            uint256 value = msg.value;
            uint256 kometFee = ((value * feePercent) / 100) / percentDecimal;
            uint256 creator = value - kometFee;

            require(
                address(this).balance >= creator,
                "Insufficient balance to send the first transaction"
            );
            recipient1.transfer(creator);

            require(
                address(this).balance >= kometFee,
                "Insufficient balance to send the second transaction"
            );
            recipient2.transfer(kometFee);
        } else {
            uint256 kometFee = msg.value;

            require(
                address(this).balance >= kometFee,
                "Insufficient balance to send the second transaction"
            );
            recipient2.transfer(kometFee);
        }
    }
}
