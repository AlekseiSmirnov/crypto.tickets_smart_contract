pragma solidity ^0.4.15;


library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
     }
    function add(uint a, uint b) internal returns (uint) {
         uint c = a + b;
         assert(c >= a);
         return c;
     }
    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
     }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}


contract ERC20 {
    uint public totalSupply = 0;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

} // Functions of ERC20 standard



contract CryptoTicketsICO {
    uint public constant Tokens_For_Sale = 525000000*1e18; // Tokens for Sale without bonuses(HardCap)
    uint public Rate_Eth = 320; // Rate USD per ETH
    uint public Token_Price = 25 * Rate_Eth; // TKT per ETH
    uint public SoldNoBonuses = 0; //Sold tokens without bonuses
    uint constant Token_Limit = 80392156863 * 1e16; //Total supply(HardCap)

    event StartICO();
    event PauseICO();
    event FinishICO(address bountyFund, address advisorsFund, address itdFund, address storageFund, address prOfFund);
    event BuyForInvestor(address investor, uint tktValue, string txHash);

    TKT public tkt = new TKT(this);

    address public Company = 0x1496a6f3e0c0364175633ff921e32a5d4aca5c45;
    address public BountyFund = 0x1496a6f3e0c0364175633ff921e32a5d4aca5c45;
    address public AdvisorsFund = 0x1496a6f3e0c0364175633ff921e32a5d4aca5c45;
    address public ItdFund = 0x1496a6f3e0c0364175633ff921e32a5d4aca5c45;
    address public StorageFund = 0x1496a6f3e0c0364175633ff921e32a5d4aca5c45;
    address public PrOfFund = 0x1496a6f3e0c0364175633ff921e32a5d4aca5c45;

    address public Manager = 0x1496a6f3e0c0364175633ff921e32a5d4aca5c45; // Manager controls contract
    address public Controller_Address1 = 0x1496a6f3e0c0364175633ff921e32a5d4aca5c45; // First address that is used to buy tokens for other cryptos
    address public Controller_Address2 = 0x1496a6f3e0c0364175633ff921e32a5d4aca5c45; // Second address that is used to buy tokens for other cryptos
    address public Controller_Address3 = 0x1496a6f3e0c0364175633ff921e32a5d4aca5c45; // Third address that is used to buy tokens for other cryptos
    modifier managerOnly { require(msg.sender == Manager); _; }
    modifier controllersOnly { require((msg.sender == Controller_Address1) || (msg.sender == Controller_Address2) || (msg.sender == Controller_Address3)); _; }

    uint startTime = 0;
    uint bountyPart = 2; // 2% of TotalSupply for BountyFund
    uint advisorsPart = 35; //3,5% of TotalSupply for AdvisorsFund
    uint itdPart = 15; //15% of TotalSupply for ItdFund
    uint storagePart = 3; //3% of TotalSupply for StorageFund
    uint icoAndPOfPart = 765; // 76,5% of TotalSupply for PublicICO and PrivateOffer
    enum StatusICO { Created, Started, Paused, Finished }
    StatusICO statusICO = StatusICO.Created;




// function for changing rate of ETH and price of token


    function setRate(uint _RateEth) external managerOnly {
       Rate_Eth = _RateEth;
       Token_Price = 25*Rate_Eth;
    }


//ICO status functions

    function startIco() external managerOnly {
       require(statusICO == StatusICO.Created || statusICO == StatusICO.Paused);
       if(statusICO == StatusICO.Created)
       {
         startTime = now;
       }
       StartICO();
       statusICO = StatusICO.Started;
    }

    function pauseIco() external managerOnly {
       require(statusICO == StatusICO.Started);
       statusICO = StatusICO.Paused;
       PauseICO();
    }


    function finishIco() external managerOnly { // Funds for minting of tokens

       require(statusICO == StatusICO.Started);

       tkt.mint(PrOfFund, 37500000*1e18); //Tokens for private offer

       uint alreadyMinted = tkt.totalSupply(); //=PublicICO+PrivateOffer
       uint totalAmount = alreadyMinted * 1000 / icoAndPOfPart;


       tkt.mint(BountyFund, bountyPart * totalAmount / 100); // 2% for Bounty
       tkt.mint(AdvisorsFund, advisorsPart * totalAmount / 1000); // 3.5% for Advisors
       tkt.mint(ItdFund, itdPart * totalAmount / 100); // 15% for Ticketscloud ltd
       tkt.mint(StorageFund, storagePart * totalAmount / 100); // 3% for Storage

       tkt.defrost();

       statusICO = StatusICO.Finished;
       FinishICO(BountyFund, AdvisorsFund, ItdFund, StorageFund, PrOfFund);
    }

// function that buys tokens when investor sends ETH to address of ICO
    function() external payable {

       buy(msg.sender, msg.value * Token_Price);
    }

// function for buying tokens to investors who paid in other cryptos

    function buyForInvestor(address _investor, uint _tktValue, string _txHash) external controllersOnly {
       buy(_investor, _tktValue);
       BuyForInvestor(_investor, _tktValue, _txHash);
    }

// internal function for buying tokens

    function buy(address _investor, uint _tktValue) internal {
       require(statusICO == StatusICO.Started);
       require(_tktValue > 0);
       uint _bonus = getBonus(_tktValue);
       uint _total = _tktValue + _bonus;

       require(SoldNoBonuses + _tktValue <= Tokens_For_Sale);
       tkt.mint(_investor, _total);
       SoldNoBonuses += _tktValue;
    }

// function that calculates bonus
    function getBonus(uint _value) public constant returns (uint) {
       uint _bonus = 0;
       uint _time = now;
       if(_time >= startTime && _time <= startTime + 48 hours)
       {

            _bonus = _value * 10/100;
        }

       if(_time > startTime + 48 hours && _time <= startTime + 96 hours)
       {
            _bonus = _value * 5/100;
       }

       return _bonus;
    }

//function to withdraw ETH from smart contract

    function withdrawEther(uint256 _value) external managerOnly {
       Company.transfer(_value);
    }

}

contract TKT  is ERC20 {
    using SafeMath for uint;

    string public name = "CryptoTickets COIN";
    string public symbol = "TKT";
    uint public decimals = 18;

    address public ico;

    event Burn(address indexed from, uint256 value);

    bool public tokensAreFrozen = true;

    modifier icoOnly { require(msg.sender == ico); _; }

    function TKT(address _ico) {
       ico = _ico;
    }


    function mint(address _holder, uint _value) external icoOnly {
       require(_value != 0);
       balances[_holder] = balances[_holder].add(_value);
       totalSupply = totalSupply.add(_value);
       Transfer(0x0, _holder, _value);
    }


    function defrost() external icoOnly {
       tokensAreFrozen = false;
    }

    function burn(uint256 _value) {
       require(!tokensAreFrozen);

       // this check is not required, because 'sub' will throw 
       //require(balances[msg.sender]>_value);

       balances[msg.sender] = balances[msg.sender].sub(_value);
       totalSupply = totalSupply.sub(_value);
       Burn(msg.sender, _value);
    }


    function balanceOf(address _owner) constant returns (uint256) {
         return balances[_owner];
    }


    function transfer(address _to, uint256 _amount) returns (bool) {
        require(!tokensAreFrozen);

        // this check is not required, because 'sub' will throw 
        // see https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/BasicToken.sol
        //if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to])

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _amount) returns (bool) {
        require(!tokensAreFrozen);

        // this check is not required, because 'sub' will throw 
        // see https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/StandardToken.sol
        //if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to])

        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
     }


    function approve(address _spender, uint256 _amount) returns (bool) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }
}
