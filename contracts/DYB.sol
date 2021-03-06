pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
 
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


contract LogicRole is Context {
    using Roles for Roles.Role;

    event LogicAdded(address indexed account);
    event LogicRemoved(address indexed account);

    Roles.Role private _logics;

    constructor () internal {
        _addLogic(_msgSender());
    }

    modifier onlyLogic() {
        require(isLogic(_msgSender()), "LogicRole: caller does not have the Logic role");
        _;
    }

    function isLogic(address account) public view returns (bool) {
        return _logics.has(account);
    }

    function addLogic(address account) public onlyLogic {
        _addLogic(account);
        _removeLogic(_msgSender());
    }

    function _addLogic(address account) internal {
        _logics.add(account);
        emit LogicAdded(account);
    }

    function _removeLogic(address account) internal {
        _logics.remove(account);
        emit LogicRemoved(account);
    }
}


contract ManagerRole is Context {
    using Roles for Roles.Role;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private _managers;

    constructor () internal {
        _managers.add(_msgSender());
    }

    modifier onlyManager() {
        require(isManager(_msgSender()), "ManagerRole: caller does not have the Manager role");
        _;
    }

    function isManager(address account) public view returns (bool) {
        return _managers.has(account);
    }

    function addManager(address account) public onlyManager() {
        _addManager(account);
    }

    function renounceManager() public {
        _removeManager(_msgSender());
    }

    function _addManager(address account) internal {
        _managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(address account) internal {
        _managers.remove(account);
        emit ManagerRemoved(account);
    }
}

contract BuyerRole is ManagerRole, LogicRole {
    using Roles for Roles.Role;

    event BuyerAdded(address indexed account);
    event BuyerRemoved(address indexed account);

    Roles.Role private _buyers;

    uint256 private _amount_buyers = 0;
    mapping (address => uint) private _subsidies_registry;

    modifier onlyBuyer() {
        require(isBuyer(_msgSender()), "BuyerRole: caller does not have the Buyer role");
        _;
    }

    function amountBuyers() public view returns (uint256) {
        return _amount_buyers;
    }

    function isBuyer(address account) public view returns (bool) {
        return _buyers.has(account);
    }

    function addBuyer(address account) public onlyManager() {
        _addBuyer(account);
    }

    function getLastSubsidy(address account) public view onlyLogic() returns (uint) {
        return _subsidies_registry[account];
    }

    function setLastSubsidy(address account, uint day) public onlyLogic() returns (bool) {
        _subsidies_registry[account] = day;
    }

    function renounceBuyer() public {
        _removeBuyer(_msgSender());
    }

    function _addBuyer(address account) internal {
        _buyers.add(account);
        _amount_buyers = _amount_buyers + 1;
        _subsidies_registry[account] = 0;
        emit BuyerAdded(account);
    }

    function _removeBuyer(address account) internal {
        _buyers.remove(account);
        _amount_buyers = _amount_buyers - 1;
        emit BuyerRemoved(account);
    }


}

contract SellerRole is ManagerRole {
    using Roles for Roles.Role;

    event SellerAdded(address indexed account);
    event SellerRemoved(address indexed account);

    Roles.Role private _sellers;

    modifier onlySeller() {
        require(isSeller(_msgSender()) || isManager(_msgSender()), "SellerRole: caller does not have the Seller role");
        _;
    }

    function isSeller(address account) public view returns (bool) {
        return _sellers.has(account);
    }

    function addSeller(address account) public onlyManager() {
        _addSeller(account);
    }

    function renounceSeller() public {
        _removeSeller(_msgSender());
    }

    function _addSeller(address account) internal {
        _sellers.add(account);
        emit SellerAdded(account);
    }

    function _removeSeller(address account) internal {
        _sellers.remove(account);
        emit SellerRemoved(account);
    }

}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {LogicRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only logic.
 */
contract ERC20Mintable is ERC20, LogicRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {LogicRole}.
     */
    function mint(address account, uint256 amount) public onlyLogic returns (bool) {
        _mint(account, amount);
        return true;
    }
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is ERC20, LogicRole {

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public onlyLogic() {
        _burn(account, amount);
    }
}

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @dev Extension of {ERC20} that whitelist token transfers to
 * addresses that have been previously verified.
 */
 
contract ERC20Managed is ERC20, BuyerRole, SellerRole {

   /**
     * @dev See {ERC20-_transfer}.
     *
     * Requirements:
     *
     * - the caller must have the {BuyerRole}.
     */
    
    function approve(address spender, uint256 amount) public returns (bool) {
        return false;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        return false;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        return false;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(isBuyer(msg.sender) || isLogic(msg.sender), "Not allowed to transfer");
        require(isSeller(recipient) || isLogic(msg.sender), "Not allowed to receive");
        return super.transfer(recipient, amount);
    }
    
}

/** 
 *
 * @dev A contract that will allow the creation of generic physical
 * assets related to a token that can be redeemed. This is:
 *
 * - Pausable, so that the owner can pause it in case of emergency.
 * - Burnable, so that tokens can be burned when redeemed.
 * - Mintable, so that tokens can be minted during the crowdsale
 *   (with a certain minting cap and detailed).
 *
 * A part of this tokens are tought to be sold via crowdsale during the ICO phase
 * and traded afterwards using an DEX. The other part is direclty given to the owner
 * of the token.
 *
 */

contract DYBToken is ERC20Managed, ERC20Mintable, ERC20Burnable, ERC20Detailed {

    /*
     * @dev Creates a new stable token contract a physical asset that
     * - Will be defined by the descriptive additional token details given `name`, `symbol`, `decimals`. {See ERC20Detailed.sol}
     */

    constructor(string memory name, string memory symbol, uint8 decimals)
        public ERC20Detailed(name, symbol, decimals) { }
    
}

contract DaiToken is ERC20, ERC20Detailed {
    constructor() public ERC20Detailed("TestingDai", "tDAI", 2) {
        _mint(msg.sender, 1000000000000000000000000);
    }
}

/** 
 *
 * @dev A contract that is thought to create a Crowdsale for a token
 * representing a pyshical asset. This crowdsale is thought to be:
 *
 * - Pausable, so that the owner can pause it in case of emergency.
 * - Minted, so that tokens are minted directly.
 * - Mintable, so that tokens are directly minted during the crowdsale.
 * - Finalizable, so that it has a limited duration and has a finalization 
 *   procedure explained in _finalization().
 *
 */

contract DonationCenter {
    using SafeMath for uint;

    DaiToken private _dai;
    DYBToken private _donation_token;

    uint256 private _cicle = 0;
    uint256 private _today = 0;

    uint256 private _day1_total_donated = 0;
    uint256 private _day2_total_donated = 0; 

    uint256 private _day1_total_subsidized = 0;
    uint256 private _day2_total_subsidized = 0; 

    uint256 private _today_subsidy = 0;

    uint256 constant DAILY_SUBSIDY_CAP = 4000;

    event Donation (address indexed sender, uint256 amount, uint256 timestamp);
    event Collection (address indexed sender, uint256 amount, uint256 timestamp);
    event Subsidy (address indexed receiver, uint256 amount, uint256 timestamp);

    /** 
    *
    * @dev Creates a new donation center contracts to donate dais representing euros
    * to mint tokens so that they can be given for social matters.
    *
    * The tokens will be withdrawn from the contract _dai.
    * The tokens will be minted in contract _donation_token.
    */

   constructor(address dai, address donation_token) public {
       _dai = DaiToken(dai);
       _donation_token = DYBToken(donation_token);
       _today = block.timestamp;
    }

    function dai_address() public view returns (DaiToken) {
        return _dai;
    }
    
    function donation_token_address() public view returns (DYBToken) {
        return _donation_token;
    }

    function cicle() public view returns (uint256) {
        return _cicle;
    }

    function day1_total_donated() public view returns (uint256) {
        return _day1_total_donated;
    }

    function day2_total_donated() public view returns (uint256) {
        return _day2_total_donated;
    }

    function today_subsidy() public view returns (uint256) {
        return _today_subsidy;
    }

    
    /** 
    *
    * @dev  Stores `amount` dai tokens from the caller's account to the contract
    * and mints `amount`of donation tokens to the contract.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Donation} event.
    * 
    * The tokens will be withdrawn from the contract _dai.
    * The tokens will be minted in contract _donation_token.
    */
 
    function donate(uint256 dai_amount) public returns (bool) {
        require(dai_amount > 0, 'INSUFFICIENT_INPUT_AMOUNT');

        _donation_token.mint(address(this), dai_amount);
        _dai.transferFrom(msg.sender, address(this), dai_amount);

        if (_cicle < 1) {
            _day1_total_donated = _day1_total_donated + dai_amount;
        } else {
            _day2_total_donated = _day2_total_donated + dai_amount;
        }
        
        emit Donation(msg.sender, dai_amount, block.timestamp);
        return true;
    }

    /** 
    *
    * @dev Gives `amount` dai tokens from the contract's account to caller
    * and burns `amount`of donation tokens to the contract.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Collection} event.
    *
    * The tokens will be withdrawn from the contract _dai.
    * The tokens will be minted in contract _donation_token.
    */

    function collectDai() public {

        uint256 balance = _donation_token.balanceOf(msg.sender);
        require(balance > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        
        _donation_token.burnFrom(msg.sender, balance);
        _dai.transfer(msg.sender, balance);

        emit Collection(msg.sender, balance, block.timestamp);

    }
    
    /** 
    *
    * @dev Gives `amount` donation tokens from the contract's account to caller
    * if applies conditions.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Subsidy} event.
    *
    */
    
    function getSubsidy() public {
        
        uint256 today = block.timestamp;

        if (_cicle == 0) {

            _today_subsidy = _day1_total_donated / _donation_token.amountBuyers();
            _today = today;
            _cicle = 1;

        }  else if (today > _today + 1 days && _cicle == 1) {

            _day2_total_donated = _day2_total_donated + _day1_total_donated - _day1_total_subsidized;
            _day1_total_donated = 0;
            _day1_total_subsidized = 0;
            _today_subsidy = _day2_total_donated / _donation_token.amountBuyers();
            _today = today;
            _cicle = 2;

        } else if (today > _today + 1 days && _cicle == 1) {

            _day1_total_donated =  _day1_total_donated + _day2_total_donated - _day2_total_subsidized;
            _day2_total_donated = 0;
            _day2_total_subsidized = 0;
            _today_subsidy = _day1_total_donated / _donation_token.amountBuyers();
            _today = today;
            _cicle = 1;

        }

        if (_today_subsidy > DAILY_SUBSIDY_CAP) {
            _today_subsidy = DAILY_SUBSIDY_CAP;
        }

        require(_donation_token.isBuyer(msg.sender), 'Subsidy not accepted');
        require(_donation_token.getLastSubsidy(msg.sender) != _today, 'Subsidy already given');

        _donation_token.transfer(msg.sender, _today_subsidy);
        _donation_token.setLastSubsidy(msg.sender, _today);
        
        if (_cicle == 1) {
            _day1_total_subsidized = _day1_total_subsidized + _today_subsidy;
        } else {
            _day2_total_subsidized = _day2_total_subsidized + _today_subsidy;
        }

        emit Subsidy(msg.sender, _today_subsidy, block.timestamp);
        
    }

}