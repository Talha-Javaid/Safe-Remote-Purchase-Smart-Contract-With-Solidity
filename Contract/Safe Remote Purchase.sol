// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract SafeRemotePurchase{

    uint public itemValue;
    address payable public SELLER;
    address payable public BUYER;

    error OrderHaveNotPlacedYet();
    error OrderPlacedButNotConfirmed();
    error ConfirmedButNotDelivered();
    error DeliveredButPaymentIsPending();
    error TooLateToAbortOrder();

    event SellerState(address SellerAddress,Status status);
    event BuyerState(address BuyerAddress,Status status);
    event SellerDetails(address SellerAddress,uint ItemValue,Status status);
    event BuyerDetails(address BuyerAddress,uint ItemValue,Status status);

    constructor() payable {
        SELLER=payable(msg.sender);
        itemValue= msg.value / 2;
        emit SellerDetails(msg.sender, msg.value,Status.Created);
    }

    modifier onlyBuyer() {
        require(msg.sender==BUYER,"Only buyer is authorized");
        _;
    }

    modifier onlySeller() {
        require(msg.sender==SELLER,"Only seller is authorized");
        _;
    }
    
    enum Status{

        Created, 
        Locked, 
        Dispatched, 
        Delivered, 
        Inactive
    }
    
    Status public status;
    
    /**
    
       * @dev GetBuyerBalance for getting Buyer account balance
       
    **/

    function GetBuyerBalance() external view returns(uint) 
    {
        return address(BUYER).balance;
    }

    /**
    
       * @dev GetSellerBalance for getting Seller account balance
       
    **/

    function GetSellerBalance() external view returns(uint) 
    {
        return address(SELLER).balance;
    }
    
    /**
    
       * @dev ConfirmPurchase for purchase confirmation
       * Requirements:
       * Check: Order status must be created
       * Check: Amount to be sent must equal to 2x item amount
       * Emits a BuyerDetails event
    
    **/

    function ConfirmPurchase() 
    external 
    payable  
    {    
        if(status!=Status.Created)
    {
        revert OrderHaveNotPlacedYet();
    }
        //require(status==Status.Created,"The item isn't created yet");
        require(msg.value== 2 * itemValue,"ItemValue should be double than purchase amount");
        BUYER= payable(msg.sender);
        status=Status.Locked;     
        emit BuyerDetails(msg.sender, msg.value, Status.Locked);
    }

    /**
    
       * @dev DispatchItem for dispatching item purchased
       * Requirements:
       * Check: Order status must be Locked
       * onlySeller is allowed to perform this function
       * Emits a SellerState event
    
    **/

    function DispatchItem() 
    external 
    onlySeller
    { 
        if (status!=Status.Locked)
    {
        revert OrderPlacedButNotConfirmed();
    }   
        //require(status==Status.Locked,"The item is created but not confirmed yet");   
        status=Status.Dispatched;
        emit SellerState(msg.sender, Status.Dispatched);
    }

    /**
    
       * @dev ConfirmReceived for confirmation of item receive by buyer
       * Requirements:
       * Check: Order status must be Dispatched
       * onlyBuyer is allowed to perform this function
       * Emits a BuyerState event
    
    **/

    function ConfirmReceived() 
    external 
    onlyBuyer 
    {
        if (status!=Status.Dispatched)
    {
        revert ConfirmedButNotDelivered();
    }
        //require(status==Status.Dispatched,"Order is placed but not delivered");
        BUYER.transfer(itemValue);
        status=Status.Delivered;       
        emit BuyerState(msg.sender, Status.Delivered);
    }

    /**
    
       * @dev PaySeller for inactive order track record
       * Requirements:
       * Check: Order status must be Delivered
       * onlySeller is allowed to perform this function
       * Emits a SellerState event
    
    **/


    function PaySeller() 
    external 
    onlySeller 
    {
        if (status!=Status.Delivered)
    {
        revert DeliveredButPaymentIsPending();
    }
        //require(status==Status.Delivered,"The item is created but yet to be released");
        SELLER.transfer(3 * itemValue);
        status=Status.Inactive;   
        emit SellerState(msg.sender, Status.Inactive);
    }
    
    /**
    
       * @dev Abort : to cancel order before confirmation
       * Requirements:
       * Check: Order status must not be Created
       * onlySeller is allowed to perform this function
       * Emits a SellerState event
    
    **/


    function Abort() 
    external 
    onlySeller 
    {
        if(status==Status.Created)
    {
        revert TooLateToAbortOrder();
    }
        //require(status==Status.Created,"The item is confirmed now and can't be aborted");
        SELLER.transfer(address(this).balance);
        status=Status.Inactive; 
        emit SellerState(msg.sender, Status.Inactive);     
    }

}
