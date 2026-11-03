// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../contracts/SHARE.sol";
import "../../contracts/SPLIT.sol";
import "../../contracts/lemodadeStand.sol";

contract ShareTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");
    XRCSHARE share;

    function setUp() public {
        vm.prank(alice);
        share = new XRCSHARE("Stand", "LMN", 10, "uri");
        vm.deal(address(this), 1e30);
    }

    function test_MintsOneTokenPerShareToDeployer() public {
        for (uint i = 0; i < 10; i++) assertEq(share.balanceOf(alice, i), 1);
    }

    function test_SupplyAbove1000Reverts() public {
        vm.expectRevert("at most 1000 shares are allowed");
        new XRCSHARE("Big", "BIG", 1001, "uri");
        vm.expectRevert("at least one share is required");
        new XRCSHARE("None", "NONE", 0, "uri");
    }

    function test_PaymentSplitsEvenlyAcrossShareAccounts() public {
        (bool ok, ) = address(share).call{value: 100 ether}("");
        assertTrue(ok);
        for (uint i = 0; i < 10; i++) assertEq(share.viewAccount(i), 10 ether);
    }

    function test_RedeemPaysOnlyTheSharesTheCallerHolds() public {
        vm.prank(alice);
        share.safeTransferFrom(alice, bob, 3, 1, "");
        (bool ok, ) = address(share).call{value: 100 ether}("");
        assertTrue(ok);
        vm.prank(bob);
        share.redeem();
        assertEq(bob.balance, 10 ether);
        assertEq(share.viewAccount(3), 0);
        assertEq(share.viewAccount(0), 10 ether);
    }

    function test_NonHolderCannotRedeem() public {
        vm.prank(bob);
        vm.expectRevert("only token holders can access");
        share.redeem();
    }

    function test_UnclaimedDividendsTravelWithTheToken() public {
        (bool ok, ) = address(share).call{value: 100 ether}("");
        assertTrue(ok);
        vm.prank(alice);
        share.safeTransferFrom(alice, bob, 0, 1, "");
        vm.prank(bob);
        share.redeem();
        assertEq(bob.balance, 10 ether);
    }

    function test_SplitPaysSplitHoldersFromTheShare() public {
        vm.startPrank(alice);
        XRCSPLIT split = new XRCSPLIT(payable(address(share)), "uri");
        share.setApprovalForAll(address(split), true);
        split.activateContract(0);
        split.safeTransferFrom(alice, bob, 1, 1, "");
        vm.stopPrank();
        assertEq(split.generation(), 1);
        (bool ok, ) = address(share).call{value: 100 ether}("");
        assertTrue(ok);
        vm.prank(bob);
        split.redeem();
        assertEq(bob.balance, 1 ether);
    }

    function pay(uint amount) internal {
        (bool ok, ) = address(share).call{value: amount}("");
        assertTrue(ok);
    }

    function activatedSplit() internal returns (XRCSPLIT split) {
        vm.startPrank(alice);
        split = new XRCSPLIT(payable(address(share)), "uri");
        share.setApprovalForAll(address(split), true);
        split.activateContract(0);
        vm.stopPrank();
    }

    function test_AccountsKeepsItsShape() public {
        pay(100 ether);
        (uint amount, bool exist) = share.accounts(3);
        assertEq(amount, 10 ether);
        assertTrue(exist);
        (amount, exist) = share.accounts(10);
        assertEq(amount, 0);
        assertFalse(exist);
    }

    function test_ViewAccountTotalCoversHeldShares() public {
        vm.prank(alice);
        share.safeTransferFrom(alice, bob, 3, 1, "");
        pay(100 ether);
        vm.prank(bob);
        assertEq(share.viewAccountTotal(), 10 ether);
        vm.prank(alice);
        assertEq(share.viewAccountTotal(), 90 ether);
    }

    function test_DividendsKeepAccruingAfterARedeem() public {
        vm.prank(alice);
        share.safeTransferFrom(alice, bob, 3, 1, "");
        pay(100 ether);
        vm.prank(bob);
        share.redeem();
        pay(50 ether);
        assertEq(share.viewAccount(3), 5 ether);
        assertEq(share.viewAccount(0), 15 ether);
    }

    function test_WhatDoesNotDivideCarriesIntoTheNextPayment() public {
        pay(5);
        assertEq(share.viewAccount(0), 0);
        assertEq(share.remainder(), 5);
        pay(5);
        assertEq(share.viewAccount(0), 1);
        assertEq(share.remainder(), 0);
    }

    function test_RedirectValueCreditsTheShares() public {
        vm.prank(alice);
        lemonadeStand stand = new lemonadeStand("Stand", "LMN", 10, "uri");
        stand.GlassOfLemonade{value: 10 ether}();
        assertEq(stand.viewAccount(0), 1 ether);
        assertEq(stand.lemonadeCount(), 1);
    }

    function test_FailedPayoutRevertsAndKeepsTheBalance() public {
        Rejector r = new Rejector();
        vm.prank(alice);
        share.safeTransferFrom(alice, address(r), 0, 1, "");
        pay(100 ether);
        vm.prank(address(r));
        vm.expectRevert("payment failed");
        share.redeem();
        assertEq(share.viewAccount(0), 10 ether);
    }

    function test_ReentrantHolderIsPaidOnce() public {
        ReentrantHolder h = new ReentrantHolder();
        vm.prank(alice);
        share.safeTransferFrom(alice, address(h), 0, 1, "");
        pay(100 ether);
        h.attack(share);
        assertEq(address(h).balance, 10 ether);
        assertEq(address(share).balance, 90 ether);
    }

    function test_KnownLimit_PaymentWith2300GasFails() public {
        (bool ok, ) = address(share).call{value: 1 ether, gas: 2300}("");
        assertFalse(ok);
    }

    function test_GasForAPaymentDoesNotDependOnTheNumberOfShares() public {
        vm.prank(alice);
        XRCSHARE big = new XRCSHARE("Big", "BIG", 1000, "uri");
        uint before = gasleft();
        (bool ok, ) = address(big).call{value: 1000 ether}("");
        uint used = before - gasleft();
        emit log_named_uint("gas for first payment to 1000 shares", used);
        assertTrue(ok);
        assertLt(used, 100000);
    }

    function test_SplitViewBeforeActivationShowsNothing() public {
        pay(100 ether);
        vm.prank(alice);
        XRCSPLIT split = new XRCSPLIT(payable(address(share)), "uri");
        (uint own, uint fromSource, uint total) = split.viewAccount(0);
        assertEq(own + fromSource + total, 0);
        (, bool exist) = split.accounts(0);
        assertFalse(exist);
    }

    function test_SplitRefusesPaymentsBeforeActivation() public {
        XRCSPLIT split = new XRCSPLIT(payable(address(share)), "uri");
        (bool ok, ) = address(split).call{value: 1 ether}("");
        assertFalse(ok);
    }

    function test_SplitRefusesTokensOutsideActivation() public {
        XRCSPLIT split = activatedSplit();
        vm.prank(alice);
        vm.expectRevert();
        share.safeTransferFrom(alice, address(split), 1, 1, "");
    }

    function test_SplitViewMatchesWhatIsPaid() public {
        XRCSPLIT split = activatedSplit();
        vm.prank(alice);
        split.safeTransferFrom(alice, bob, 1, 1, "");
        pay(100 ether);
        (uint own, uint fromSource, uint total) = split.viewAccount(1);
        assertEq(own, 0);
        assertEq(fromSource, 1 ether);
        assertEq(total, 1 ether);
        vm.prank(bob);
        split.redeem();
        assertEq(bob.balance, 1 ether);
        (own, fromSource, total) = split.viewAccount(1);
        assertEq(total, 0);
        (own, fromSource, total) = split.viewAccount(2);
        assertEq(own, 1 ether);
        assertEq(total, 1 ether);
    }

    function test_RedeemShardNeedsEverySplit() public {
        XRCSPLIT split = activatedSplit();
        vm.startPrank(alice);
        split.safeTransferFrom(alice, bob, 1, 1, "");
        vm.expectRevert("you must hold all splits");
        split.redeemShard();
        vm.stopPrank();
    }

    function test_RedeemShardNoticesAMissingSplitAtAnyPosition() public {
        for (uint missing = 0; missing < 10; missing++) {
            vm.prank(alice);
            XRCSHARE s = new XRCSHARE("Stand", "LMN", 10, "uri");
            vm.startPrank(alice);
            XRCSPLIT split = new XRCSPLIT(payable(address(s)), "uri");
            s.setApprovalForAll(address(split), true);
            split.activateContract(0);
            split.safeTransferFrom(alice, bob, missing, 1, "");
            vm.expectRevert("you must hold all splits");
            split.redeemShard();
            vm.stopPrank();
        }
    }

    function test_RedeemShardPaysEarningsThenReturnsTheShare() public {
        XRCSPLIT split = activatedSplit();
        pay(100 ether);
        vm.prank(alice);
        split.redeemShard();
        assertEq(share.balanceOf(alice, 0), 1);
        assertEq(alice.balance, 10 ether);
        assertEq(address(split).balance, 0);
        for (uint i = 0; i < 10; i++) assertEq(split.balanceOf(alice, i), 0);
        assertFalse(split.activated());
    }

    function test_RedeemShardIncludesWhatWasTooSmallToDivide() public {
        XRCSPLIT split = activatedSplit();
        pay(150);
        vm.prank(alice);
        split.redeemShard();
        assertEq(alice.balance, 15);
        assertEq(address(split).balance, 0);
    }

    function test_ReactivationOwesNothingStale() public {
        XRCSPLIT split = activatedSplit();
        vm.prank(alice);
        split.safeTransferFrom(alice, bob, 1, 1, "");
        pay(100 ether);
        vm.prank(bob);
        split.redeem();
        vm.prank(bob);
        split.safeTransferFrom(bob, alice, 1, 1, "");
        vm.startPrank(alice);
        split.redeemShard();
        split.activateContract(0);
        vm.stopPrank();
        (uint own, uint fromSource, uint total) = split.viewAccount(1);
        assertEq(own + fromSource + total, 0);
        pay(100 ether);
        (, , total) = split.viewAccount(1);
        assertEq(total, 1 ether);
    }

    function test_FailedSplitPayoutKeepsTheBalance() public {
        XRCSPLIT split = activatedSplit();
        Rejector r = new Rejector();
        vm.prank(alice);
        split.safeTransferFrom(alice, address(r), 1, 1, "");
        pay(100 ether);
        vm.prank(address(r));
        vm.expectRevert("payment failed");
        split.redeem();
        (, , uint total) = split.viewAccount(1);
        assertEq(total, 1 ether);
    }

    function test_TwoGenerationsOfSplitsPay() public {
        XRCSPLIT first = activatedSplit();
        vm.startPrank(alice);
        XRCSPLIT second = new XRCSPLIT(payable(address(first)), "uri");
        first.setApprovalForAll(address(second), true);
        second.activateContract(0);
        second.safeTransferFrom(alice, bob, 3, 1, "");
        vm.stopPrank();
        assertEq(second.generation(), 2);

        pay(100 ether);
        (, uint fromSource, uint total) = second.viewAccount(3);
        assertEq(fromSource, 0.1 ether);
        assertEq(total, 0.1 ether);

        vm.prank(bob);
        second.redeem();
        assertEq(bob.balance, 0.1 ether);
        assertEq(address(second).balance, 0.9 ether);
        assertEq(address(first).balance, 9 ether);
        assertEq(address(share).balance, 90 ether);
    }

    function test_SecondGenerationRedeemShardReturnsTheFirstGenerationSplit() public {
        XRCSPLIT first = activatedSplit();
        vm.startPrank(alice);
        XRCSPLIT second = new XRCSPLIT(payable(address(first)), "uri");
        first.setApprovalForAll(address(second), true);
        second.activateContract(0);
        vm.stopPrank();
        pay(100 ether);
        vm.prank(alice);
        second.redeemShard();
        assertEq(first.balanceOf(alice, 0), 1);
        assertEq(alice.balance, 1 ether);
    }

    function testFuzz_NobodyWithdrawsMoreThanWasPaid(uint64[4] memory payments, uint8 buyer) public {
        XRCSPLIT split = activatedSplit();
        uint token = buyer % 10;
        vm.prank(alice);
        split.safeTransferFrom(alice, bob, token, 1, "");
        vm.prank(alice);
        share.safeTransferFrom(alice, carol, 1 + (buyer % 9), 1, "");

        uint totalPaid;
        for (uint i = 0; i < 4; i++) {
            pay(payments[i]);
            totalPaid += payments[i];
            if (i % 2 == 1) {
                vm.prank(bob);
                split.redeem();
            }
        }
        vm.prank(carol);
        share.redeem();
        vm.prank(alice);
        share.redeem();
        vm.prank(alice);
        split.redeem();
        vm.prank(bob);
        split.redeem();

        uint out = alice.balance + bob.balance + carol.balance;
        assertLe(out, totalPaid);
        assertEq(out + address(share).balance + address(split).balance, totalPaid);
        assertLt(address(share).balance, 10); // only the part that could not divide
        assertLe(address(split).balance, 18);
    }
}

contract Rejector {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

contract ReentrantHolder {
    XRCSHARE share;

    function attack(XRCSHARE _share) external {
        share = _share;
        share.redeem();
    }

    receive() external payable {
        try share.redeem() {} catch {}
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
