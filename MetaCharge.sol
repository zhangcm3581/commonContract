// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract MetaCharge is AccessControlEnumerable {
    using SafeERC20 for IERC20;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public meb = 0x7268B479eb7CE8D1B37Ef1FFc3b82d7383A1162d;
    address public usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public lp = 0x9b22403637F18020B78696766d2Be7De2F1a67e2;
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public metaPoint = 0x0a29702D828C3bd9bA20C8d0cD46Dfb853422E98;

    IUniswapV2Router01 swapRouter;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OPERATOR_ROLE, _msgSender());

        swapRouter = IUniswapV2Router01(router);
        IERC20(usdt).safeApprove(router, 2**255);
        IERC20(meb).safeApprove(router, 2**255);
        IERC20(lp).safeApprove(router, 2**255);
        IERC20(lp).safeApprove(metaPoint, 2**255);
    }

    function addLiquidity(uint256 usdtAmount, uint256 mebAmount)
        external
        onlyRole(OPERATOR_ROLE)
    {
        swapRouter.addLiquidity(
            usdt,
            meb,
            usdtAmount,
            mebAmount,
            0,
            0,
            address(this),
            block.timestamp + 30
        );
    }

    function removeLiquidity(uint256 amount) external onlyRole(OPERATOR_ROLE) {
        swapRouter.removeLiquidity(
            meb,
            usdt,
            amount,
            0,
            0,
            address(this),
            block.timestamp + 30
        );
    }

    function mebToUsdt(uint256 amount) external onlyRole(OPERATOR_ROLE) {
        address[] memory path = new address[](2);
        path[0] = address(meb);
        path[1] = address(usdt);
        swapRouter.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 30
        );
    }

    function usdtToMeb(uint256 amount) external onlyRole(OPERATOR_ROLE) {
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(meb);
        swapRouter.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 30
        );
    }

    function mebToLp(uint256 amount) external onlyRole(OPERATOR_ROLE) {
        address[] memory path = new address[](2);
        path[0] = address(meb);
        path[1] = address(usdt);
        uint256 usdtAmount = swapRouter.swapExactTokensForTokens(
            amount / 2,
            0,
            path,
            address(this),
            block.timestamp + 30
        )[0];
        swapRouter.addLiquidity(
            usdt,
            meb,
            usdtAmount,
            amount / 2,
            0,
            0,
            address(this),
            block.timestamp + 30
        );
    }

    function lpToMeb(uint256 amount) external onlyRole(OPERATOR_ROLE) {
        (, uint256 usdtAmount) = swapRouter.removeLiquidity(
            meb,
            usdt,
            amount,
            0,
            0,
            address(this),
            block.timestamp + 30
        );
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(meb);
        swapRouter.swapExactTokensForTokens(
            usdtAmount,
            0,
            path,
            address(this),
            block.timestamp + 30
        )[0];
    }

    function metaCharge(uint256 amount) external onlyRole(OPERATOR_ROLE) {
        IMetaPoint(metaPoint).rcgCreator(amount);
    }
}

interface IMetaPoint {
    function rcgCreator(uint256 amount) external;
}

interface IUniswapV2Router01 {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}