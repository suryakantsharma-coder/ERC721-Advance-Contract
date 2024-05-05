//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import


contract AllowOperations {
    bool internal _isPublic;
    bool internal _isWL;




    function getOperationStatus() public view returns(bool  _WL, bool _Public) {
       return (
        _isWL,
        _isPublic
       );
    }

    function setOperations(bool _wl, bool _public) external  {
        _isWL = _wl;
        _isPublic = _public;
    }

    

}