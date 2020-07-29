pragma solidity >=0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";


contract StarNotary is ERC721,ERC721Full {

    constructor(string memory _name, string memory _symbol) public ERC721Full(_name, _symbol){}

    struct Star {
        string name;
    }

    struct exchange{
        uint256 CouterPartyTokenID;
        bool consent;
    }

    mapping(uint256 => Star) public tokenIdToStarInfo;
    mapping(uint256 => uint256) public starsForSale;
    mapping(uint256 => exchange) public ExchangeConsent;


    // Create Star using the Struct
    function createStar(string memory _name, uint256 _tokenId) public { // Passing the name and tokenId as a parameters
        Star memory newStar = Star(_name); // Star is an struct so we are creating a new Star
        tokenIdToStarInfo[_tokenId] = newStar; // Creating in memory the Star -> tokenId mapping
        _mint(msg.sender, _tokenId); // _mint assign the the star with _tokenId to the sender address (ownership)
    }

    // Putting an Star for sale (Adding the star tokenid into the mapping starsForSale, first verify that the sender is the owner)
    function putStarUpForSale(uint256 _tokenId, uint256 _price) public {
        require(ownerOf(_tokenId) == msg.sender, "You can't sell the Star you don't owned");
        starsForSale[_tokenId] = _price;
    }


    // Function that allows you to convert an address into a payable address
    function _make_payable(address x) internal pure returns (address payable) {
        return address(uint160(x));
    }

    function buyStar(uint256 _tokenId) public  payable {
        require(starsForSale[_tokenId] > 0, "The Star should be up for sale");
        uint256 starCost = starsForSale[_tokenId];
        address ownerAddress = ownerOf(_tokenId);
        require(msg.value > starCost, "You need to have enough Ether");

        // We can't use _addTokenTo or_removeTokenFrom functions, now we have to use _transferFrom
        _transferFrom(ownerAddress, msg.sender, _tokenId);
        // We need to make this conversion to be able to use transfer() function to transfer ethers
        address payable ownerAddressPayable = _make_payable(ownerAddress);
        ownerAddressPayable.transfer(starCost);

        // issue change
        if(msg.value > starCost) {
            msg.sender.transfer(msg.value - starCost);
        }
    }

    // look up StarInfo using token ID
    function lookUptokenIdToStarInfo(uint256 _tokenID) public view returns (string memory){
        return tokenIdToStarInfo[_tokenID].name;
    }

    // Exchange stars between users: both users must call this function separately before the exhange can take effect
    function exchangeStars(uint256 _tokenId1, uint256 _tokenId2) public {

        // Check whether the message sender owns a sta
        address ownerAddress1 = ownerOf(_tokenId1);
        address ownerAddress2 = ownerOf(_tokenId2);

        require((ownerAddress1 == msg.sender || ownerAddress2 == msg.sender), "You can't exchange the Star you don't owned");

        if (ownerAddress1 == msg.sender){
            exchange memory newExchange = exchange(_tokenId2, true);
            ExchangeConsent[_tokenId1] = newExchange; // Creating in memory the toeknID1 -> ExhangeConsent mapping
        } else if (ownerAddress2 == msg.sender){
            exchange memory newExchange = exchange(_tokenId1, true);
            ExchangeConsent[_tokenId2] = newExchange; // Creating in memory the toeknID2 -> ExhangeConsent mapping
        }

        if(ExchangeConsent[_tokenId1].CouterPartyTokenID>0 && ExchangeConsent[_tokenId2].CouterPartyTokenID>0){

            uint256 _counterPartyID1 = ExchangeConsent[_tokenId1].CouterPartyTokenID;
            uint256 _counterPartyID2 = ExchangeConsent[_tokenId2].CouterPartyTokenID;

            bool _exchangeTokenMatch = ((_counterPartyID1 == _tokenId2) && (_counterPartyID2 == _tokenId1));
            require(_exchangeTokenMatch,"Exchange Tokens do not match");

            bool _bilateralConsent = ((ExchangeConsent[_tokenId1].consent == true) && (ExchangeConsent[_tokenId2].consent == true));
            require(_bilateralConsent,"Counterparty rejects exchange");

            _transferFrom(ownerAddress1, ownerAddress2, _tokenId1);
            _transferFrom(ownerAddress2, ownerAddress1, _tokenId2);
        }
    }

    function transferStar(address _to1, uint256 _tokenId) public {
        address ownerAddress = ownerOf(_tokenId);

        require(ownerAddress == msg.sender, "You can't transfer the Star you don't owned");
        transferFrom(ownerAddress, _to1, _tokenId);
    }
}