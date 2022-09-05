// SPDX-License-Identifier: UNLICENSED

/* ****************************************
 * Features:
 * - 4% of every transaction added to the locked liquidity pool
 * - 4% redistributed to holders
 * - no minting
 *
 * Allocations:
 * - 50% of the total supply are burned from the get-go
 * - 17.5% marketing
 * - 7.5% development team and advisers
 **************************************** **/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner can't be the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Token is IBEP20, Context, Ownable {
    mapping(address => bool) private _addressesExcludedFromFees;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _reflectionOwned;
    uint256 private constant MAX = ~uint256(0);

    // Customization section start
    string private constant _name = 'test';
    string private constant _symbol = 'TEST';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1000000000000000;
    uint256 private constant _liquidityFeePercent = 4;
    uint256 private constant _taxFeePercent = 4;
    uint256 private _maxTransactionAmount = 10000000000;
    uint256 private tokenLimitBeforeLiquifying = 1000000000;
    // Customization section end

    // Remove prior to deployment
    event LogNumber(string name, uint256 numberToPrint);
    event LogString(string name, string stringToPrint);
    event LogBool(string name, bool boolToPrint);
    event LogAddress(string name, address addressToPrint);

    event Liquified(
        uint256 tokensSwapped,
        uint256 receivedFromSwap,
        uint256 tokensIntoLiqudity
    );

    bool private isLiquifying = false;
    uint256 private _totalReflections = (MAX - (MAX % _totalSupply));

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    modifier triggerIsLiquifying {
        isLiquifying = true;
        _;
        isLiquifying = false;
    }

    constructor() {
        _reflectionOwned[_msgSender()] = _totalReflections;
        _addressesExcludedFromFees[owner()] = true;
        _addressesExcludedFromFees[address(this)] = true;
        // pancake router in testnet, change this to the production router before deployment
        IUniswapV2Router02 _uniswapV2Router =
            IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        // BNB in testnet, change this to the wanted token form production before deployment
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _reflectionOwned[account] / getRateDivisor();
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(
            _allowances[sender][_msgSender()] >= amount,
            'allowance too low'
        );

        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function excludeFromFees(address _address) external onlyOwner {
        _addressesExcludedFromFees[_address] = true;
    }

    function includeInFees(address _address) external onlyOwner {
        _addressesExcludedFromFees[_address] = false;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (sender != owner() && recipient != owner())
            require(
                amount <= _maxTransactionAmount,
                'Transfer amount exceeds the max transfer amount.'
            );

        uint256 reflectedAmount = amount * getRateDivisor();

        require(
            _totalReflections >= reflectedAmount,
            'Amount must be less than total reflections'
        );
        require(_reflectionOwned[sender] >= reflectedAmount, 'balance too low');

        uint256 contractTokenBalance = balanceOf(address(this));
        if (
            contractTokenBalance >= tokenLimitBeforeLiquifying &&
            !isLiquifying &&
            sender != uniswapV2Pair
        ) {
            contractTokenBalance = contractTokenBalance >= _maxTransactionAmount
                ? _maxTransactionAmount
                : contractTokenBalance;
            liquify(contractTokenBalance);
        }

        uint256 transferredAmount = amount;

        _reflectionOwned[sender] -= reflectedAmount;
        _reflectionOwned[recipient] += reflectedAmount;

        if (
            !_addressesExcludedFromFees[sender] &&
            !_addressesExcludedFromFees[recipient]
        ) {
            uint256 reflectedTaxFee =
                calculatedTaxFee(amount) * getRateDivisor();
            uint256 reflectedLiquidityFee =
                calculatedLiquidityFee(amount) * getRateDivisor();
            transferredAmount -=
                calculatedTaxFee(amount) +
                calculatedLiquidityFee(amount);
            _reflectionOwned[recipient] -=
                reflectedTaxFee +
                reflectedLiquidityFee;
            _reflectionOwned[address(this)] += reflectedLiquidityFee;
            _totalReflections -= reflectedTaxFee;
        }

        emit Transfer(sender, recipient, transferredAmount);
    }

    receive() external payable {}

    function liquify(uint256 tokensToLiquify) private triggerIsLiquifying {
        uint256 tokensToSwap = tokensToLiquify / 2;
        uint256 unswappedTokens = tokensToLiquify - tokensToSwap;

        uint256 initialBalance = address(this).balance;

        _approve(address(this), address(uniswapV2Router), tokensToLiquify);

        address[] memory liquifyPath = new address[](2);
        liquifyPath[0] = address(this);
        liquifyPath[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            liquifyPath,
            address(this),
            block.timestamp
        );

        uint256 newBalance = address(this).balance - initialBalance;

        _approve(address(this), address(uniswapV2Router), unswappedTokens);

        uniswapV2Router.addLiquidityETH{value: newBalance}(
            address(this),
            unswappedTokens,
            0,
            0,
            owner(),
            block.timestamp
        );

        emit Liquified(tokensToSwap, 1, unswappedTokens);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != address(0), 'owner can not be address zero');

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function getRateDivisor() private view returns (uint256) {
        return _totalReflections / _totalSupply;
    }

    function calculatedTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _taxFeePercent) / 100;
    }

    function calculatedLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return (_amount * _liquidityFeePercent) / 100;
    }
}