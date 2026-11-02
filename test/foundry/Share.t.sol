// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../contracts/SHARE.sol";
import "../../contracts/SPLIT.sol";

/// Tests whose names start with test_KnownIssue pin current behaviour that is a defect.
contract ShareTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    XRCSHARE share;

    function setUp() public {
        vm.prank(alice);
        share = new XRCSHARE("Stand", "LMN", 10, "uri");
        vm.deal(address(this), 1000 ether);
    }

    function test_MintsOneTokenPerShareToDeployer() public {
        for (uint i = 0; i < 10; i++) assertEq(share.balanceOf(alice, i), 1);
    }

    function test_SupplyAbove1000Reverts() public {
        vm.expectRevert();
        new XRCSHARE("Big", "BIG", 1001, "uri");
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

    function test_KnownIssue_PaymentWith2300GasFails() public {
        (bool ok, ) = address(share).call{value: 1 ether, gas: 2300}("");
        assertFalse(ok);
    }

    function test_KnownIssue_RedeemZeroesBalanceWhenThePayoutFails() public {
        Rejector r = new Rejector();
        vm.prank(alice);
        share.safeTransferFrom(alice, address(r), 0, 1, "");
        (bool ok, ) = address(share).call{value: 100 ether}("");
        assertTrue(ok);
        vm.prank(address(r));
        assertTrue(share.redeem());
        assertEq(share.viewAccount(0), 0);
        assertEq(address(r).balance, 0);
    }

    function test_GasToPayAThousandShares() public {
        vm.prank(alice);
        XRCSHARE big = new XRCSHARE("Big", "BIG", 1000, "uri");
        uint before = gasleft();
        (bool ok, ) = address(big).call{value: 1000 ether}("");
        emit log_named_uint("gas for first payment to 1000 shares", before - gasleft());
        assertTrue(ok);
    }
}

contract Rejector {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
