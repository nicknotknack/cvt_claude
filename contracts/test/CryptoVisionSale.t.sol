// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {CryptoVisionToken} from "../src/CryptoVisionToken.sol";
import {CryptoVisionSale} from "../src/CryptoVisionSale.sol";

contract CryptoVisionSaleTest is Test {
    CryptoVisionToken public token;
    CryptoVisionSale public sale;

    address public deployer = address(this);
    address public buyer = makeAddr("buyer");
    address public buyer2 = makeAddr("buyer2");

    uint256 public constant SALE_AMOUNT = 1_000_000 ether; // 1M CVT (18 decimals)
    uint256 public constant TOTAL_SUPPLY = 11_000_000 ether;

    // Allow test contract to receive ETH (it's the owner)
    receive() external payable {}

    function setUp() public {
        token = new CryptoVisionToken();
        sale = new CryptoVisionSale(address(token));
        token.transfer(address(sale), SALE_AMOUNT);

        // Fund buyers with ETH
        vm.deal(buyer, 100 ether);
        vm.deal(buyer2, 100 ether);
    }

    // 1. Token deploys with 11M supply to deployer
    function test_TokenDeploysWithCorrectSupply() public view {
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
        assertEq(token.name(), "CryptoVision");
        assertEq(token.symbol(), "CVT");
        // deployer keeps 10M, sale has 1M
        assertEq(token.balanceOf(deployer), TOTAL_SUPPLY - SALE_AMOUNT);
    }

    // 2. Sale contract receives 1M CVT after setup
    function test_SaleContractHas1MCVT() public view {
        assertEq(token.balanceOf(address(sale)), SALE_AMOUNT);
        assertEq(sale.tokensRemaining(), SALE_AMOUNT);
    }

    // 3. Buy tokens: send 0.1 ETH -> get 1,000 CVT
    function test_BuyTokens() public {
        vm.prank(buyer);
        sale.buyTokens{value: 0.1 ether}();

        assertEq(token.balanceOf(buyer), 1_000 ether);
        assertEq(sale.totalTokensSold(), 1_000 ether);
        assertEq(address(sale).balance, 0.1 ether);
    }

    // 4. Reverts when supply exhausted
    function test_RevertWhenSupplyExhausted() public {
        // Buy all 1M tokens (costs 100 ETH)
        vm.prank(buyer);
        sale.buyTokens{value: 100 ether}();

        // Try to buy more
        vm.prank(buyer2);
        vm.expectRevert(CryptoVisionSale.InsufficientTokenSupply.selector);
        sale.buyTokens{value: 0.1 ether}();
    }

    // 5. Reverts when sale not active
    function test_RevertWhenSaleNotActive() public {
        sale.endSale();

        vm.prank(buyer);
        vm.expectRevert(CryptoVisionSale.SaleNotActive.selector);
        sale.buyTokens{value: 0.1 ether}();
    }

    // 6. endSale() returns unsold tokens + ETH to owner, only owner
    function test_EndSaleReturnsTokensAndETH() public {
        // Buyer purchases some tokens first
        vm.prank(buyer);
        sale.buyTokens{value: 1 ether}();

        uint256 ownerTokensBefore = token.balanceOf(deployer);
        uint256 ownerEthBefore = deployer.balance;

        sale.endSale();

        assertEq(sale.saleActive(), false);
        // Unsold tokens returned (1M - 10,000 = 990,000)
        assertEq(token.balanceOf(deployer), ownerTokensBefore + SALE_AMOUNT - 10_000 ether);
        assertEq(token.balanceOf(address(sale)), 0);
        // ETH returned
        assertEq(deployer.balance, ownerEthBefore + 1 ether);
        assertEq(address(sale).balance, 0);
    }

    function test_EndSaleOnlyOwner() public {
        vm.prank(buyer);
        vm.expectRevert();
        sale.endSale();
    }

    // 7. withdrawETH() sends ETH to owner, only owner
    function test_WithdrawETH() public {
        vm.prank(buyer);
        sale.buyTokens{value: 2 ether}();

        uint256 ownerEthBefore = deployer.balance;
        sale.withdrawETH();

        assertEq(deployer.balance, ownerEthBefore + 2 ether);
        assertEq(address(sale).balance, 0);
    }

    function test_WithdrawETHOnlyOwner() public {
        vm.prank(buyer);
        sale.buyTokens{value: 1 ether}();

        vm.prank(buyer);
        vm.expectRevert();
        sale.withdrawETH();
    }

    function test_WithdrawETHRevertsWhenNoBalance() public {
        vm.expectRevert(CryptoVisionSale.NoETHToWithdraw.selector);
        sale.withdrawETH();
    }

    // 8. receive() fallback triggers buy
    function test_ReceiveFallbackTriggersBuy() public {
        vm.prank(buyer);
        (bool sent,) = address(sale).call{value: 0.5 ether}("");
        assertTrue(sent);

        assertEq(token.balanceOf(buyer), 5_000 ether);
        assertEq(sale.totalTokensSold(), 5_000 ether);
    }

    // 9. Zero ETH reverts
    function test_RevertOnZeroETH() public {
        vm.prank(buyer);
        vm.expectRevert(CryptoVisionSale.MustSendETH.selector);
        sale.buyTokens{value: 0}();
    }

    // 10. Multiple buys accumulate totalTokensSold correctly
    function test_MultipleBuysAccumulate() public {
        vm.prank(buyer);
        sale.buyTokens{value: 0.1 ether}();

        vm.prank(buyer2);
        sale.buyTokens{value: 0.5 ether}();

        vm.prank(buyer);
        sale.buyTokens{value: 1 ether}();

        // 1,000 + 5,000 + 10,000 = 16,000 CVT
        uint256 expectedTotal = 16_000 ether;
        assertEq(sale.totalTokensSold(), expectedTotal);
        assertEq(token.balanceOf(buyer), 11_000 ether);
        assertEq(token.balanceOf(buyer2), 5_000 ether);
    }

    // -------------------------------------------------------------------------
    // Fuzz tests
    // -------------------------------------------------------------------------

    // Fuzz 1: Any valid ETH amount yields the correct token amount and
    // updates contract state consistently.
    // ethAmount is bounded to [1 wei, 100 ether] so it never exceeds the
    // 1M CVT sale allocation (100 ETH * 10,000 = 1,000,000 CVT).
    function testFuzz_BuyTokensCorrectAmount(uint256 ethAmount) public {
        vm.assume(ethAmount >= 1);
        vm.assume(ethAmount <= 100 ether);

        uint256 expectedTokens = ethAmount * sale.TOKENS_PER_ETH();

        address fuzzyBuyer = makeAddr("fuzzyBuyer");
        vm.deal(fuzzyBuyer, ethAmount);

        vm.prank(fuzzyBuyer);
        sale.buyTokens{value: ethAmount}();

        assertEq(token.balanceOf(fuzzyBuyer), expectedTokens, "buyer token balance mismatch");
        assertEq(sale.totalTokensSold(), expectedTokens, "totalTokensSold mismatch");
        assertEq(address(sale).balance, ethAmount, "sale ETH balance mismatch");
        assertEq(sale.tokensRemaining(), SALE_AMOUNT - expectedTokens, "tokensRemaining mismatch");
    }

    // Fuzz 2: Zero ETH always reverts.
    function testFuzz_ZeroETHAlwaysReverts(uint256 ethAmount) public {
        vm.assume(ethAmount == 0);

        vm.prank(buyer);
        vm.expectRevert(CryptoVisionSale.MustSendETH.selector);
        sale.buyTokens{value: ethAmount}();
    }

    // Fuzz 3: Any amount exceeding the 1M CVT supply reverts.
    function testFuzz_ExcessETHRevertsWithSupplyError(uint256 ethAmount) public {
        // Any amount that would require more than 1M CVT should revert.
        // 1M CVT / 10,000 TOKENS_PER_ETH = 100 ETH threshold.
        vm.assume(ethAmount > 100 ether);
        // Cap to avoid unrealistic uint256 values that waste gas.
        vm.assume(ethAmount <= 1_000_000 ether);

        address fuzzyBuyer = makeAddr("excessBuyer");
        vm.deal(fuzzyBuyer, ethAmount);

        vm.prank(fuzzyBuyer);
        vm.expectRevert(CryptoVisionSale.InsufficientTokenSupply.selector);
        sale.buyTokens{value: ethAmount}();
    }

    // Fuzz 4: Token price invariant — tokenAmount == ethAmount * TOKENS_PER_ETH with no rounding.
    function testFuzz_TokenPriceCalculation(uint256 ethAmount) public {
        vm.assume(ethAmount >= 1);
        vm.assume(ethAmount <= 100 ether);

        uint256 expectedTokens = ethAmount * sale.TOKENS_PER_ETH();

        assertGe(expectedTokens, ethAmount, "token amount must be >= ETH amount");
        assertEq(expectedTokens / sale.TOKENS_PER_ETH(), ethAmount, "price formula not invertible");

        // Confirm the contract produces the same result on-chain.
        address fuzzyBuyer = makeAddr("priceBuyer");
        vm.deal(fuzzyBuyer, ethAmount);

        vm.prank(fuzzyBuyer);
        sale.buyTokens{value: ethAmount}();

        assertEq(token.balanceOf(fuzzyBuyer), expectedTokens, "on-chain price calculation mismatch");
    }

    // Fuzz 5: Two independent buyers accumulate balances and totalTokensSold correctly.
    function testFuzz_MultipleBuyersAccumulate(uint256 eth1, uint256 eth2) public {
        vm.assume(eth1 >= 1);
        vm.assume(eth2 >= 1);
        // Combined ETH must not exceed 100 ETH (= 1M CVT).
        vm.assume(eth1 <= 50 ether);
        vm.assume(eth2 <= 50 ether);

        uint256 tokens1 = eth1 * sale.TOKENS_PER_ETH();
        uint256 tokens2 = eth2 * sale.TOKENS_PER_ETH();

        address buyerA = makeAddr("buyerA");
        address buyerB = makeAddr("buyerB");
        vm.deal(buyerA, eth1);
        vm.deal(buyerB, eth2);

        vm.prank(buyerA);
        sale.buyTokens{value: eth1}();

        vm.prank(buyerB);
        sale.buyTokens{value: eth2}();

        assertEq(token.balanceOf(buyerA), tokens1, "buyerA balance mismatch");
        assertEq(token.balanceOf(buyerB), tokens2, "buyerB balance mismatch");
        assertEq(sale.totalTokensSold(), tokens1 + tokens2, "totalTokensSold accumulation mismatch");
        assertEq(address(sale).balance, eth1 + eth2, "sale ETH accumulation mismatch");
    }

    // Fuzz 6: tokensRemaining + totalTokensSold always equals the original sale allocation.
    function testFuzz_SupplyConservation(uint256 ethAmount) public {
        vm.assume(ethAmount >= 1);
        vm.assume(ethAmount <= 100 ether);

        address fuzzyBuyer = makeAddr("conservationBuyer");
        vm.deal(fuzzyBuyer, ethAmount);

        vm.prank(fuzzyBuyer);
        sale.buyTokens{value: ethAmount}();

        assertEq(
            sale.tokensRemaining() + sale.totalTokensSold(),
            SALE_AMOUNT,
            "supply conservation invariant broken"
        );
    }
}
