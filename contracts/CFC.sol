pragma solidity 0.5.10;

import "./BEP20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract CFC is BEP20, Ownable{

    using SafeMath for uint256;
    uint public TAX_FEE = 5;
    uint public BUY_FEE = 1;
    uint public SELL_FEE = 2;
    uint32 public MAX_BUY = 150000;
    uint32 public MAX_SELL = 60000;

    mapping (address => bool) public excludedFromTax;

    /* BEP20 constants */
    string public constant Name = "ChronoFi";
    string public constant Symbol = "CFC";
    uint8 public constant decimals = 18;

    /* Suns per Satoshi = 10,000 * 1e8 / 1e8 = 1e4 */
    uint256 private constant SUNS_PER_DIV = 10**uint256(decimals); // 1e18

    /* Time of contract launch (2021-10-11T00:00:00Z) */
    uint256 internal constant LAUNCH_TIME = 1635966980;

    constructor() public {
        _mint(msg.sender, 1000 * 10 ** 18);
        excludedFromTax[msg.sender] = true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) 
    {
        if (excludedFromTax[msg.sender] == true) 
        {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
        uint tax_fee = amount.mul(TAX_FEE)/100;
        if (balanceOf(msg.sender) < (amount + tax_fee)) 
            return false;
        _transfer(_msgSender(), owner(), tax_fee);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) 
    {
        if (excludedFromTax[sender] == true) 
        {
            _transfer(sender, recipient, amount);
            return true;
        }
        uint tax_fee = amount.mul(TAX_FEE)/100;
        if (balanceOf(sender) < (amount + tax_fee)) 
            return false;
        _transfer(sender, owner(), tax_fee);
        _transfer(sender, recipient, amount);
        
        return true;
    }

    function buyToken(uint256 amount) public returns (bool) 
    {
        if (balanceOf(msg.sender).add(amount) > MAX_BUY) 
            return false;
        
        uint buy_fee = amount.mul(BUY_FEE)/100;

        if (excludedFromTax[msg.sender] == true) 
        {
            _transfer(owner(), msg.sender, amount.sub(buy_fee));
            return true;
        }
        uint tax_fee = amount.mul(TAX_FEE)/100;
        _transfer(owner(), msg.sender, amount.sub(buy_fee).sub(tax_fee));
        
        return true;
    }

    function sellToken(uint256 amount) public returns (bool) 
    {
        if (balanceOf(msg.sender).add(amount) > MAX_SELL) 
            return false;
            
        uint sell_fee = amount.mul(SELL_FEE)/100;
        uint tax_fee = amount.mul(TAX_FEE)/100;
        if(balanceOf(msg.sender) < (sell_fee + amount + tax_fee))
            return false;

        if (excludedFromTax[msg.sender] == true) 
        {
            _transfer(msg.sender, owner(), amount.add(sell_fee));
            return true;
        }
        
        _transfer(msg.sender, owner(), amount.add(sell_fee).add(tax_fee));
        return true;
    }
    
}