// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./Setup.t.sol";

contract AccessControlTest is SetupTest {
    
    function testInitialAdminState() public view {
        assertEq(accessControl.isAdmin(admin), true);
        assertEq(accessControl.isAdmin(conductor1), false);
        assertEq(accessControl.isAdmin(user1), false);
    }
    
    function testInitialConductorState() public view {
        assertEq(conductors.getConductorId(conductor1) != 0, true);
        assertEq(conductors.getConductorId(conductor2) != 0, true);
        assertEq(conductors.getConductorId(user1) == 0, true);
        assertEq(conductors.getConductorId(admin) == 0, true);
    }
    
    function testOnlyAdminCanAddAdmin() public {
        vm.prank(admin);
        accessControl.addAdmin(user1);
        assertEq(accessControl.isAdmin(user1), true);
        
        vm.prank(conductor1);
        vm.expectRevert(IonicErrors.Unauthorized.selector);
        accessControl.addAdmin(conductor2);
    }
    
    function testOnlyAdminCanRemoveAdmin() public {
        vm.prank(admin);
        accessControl.addAdmin(user1);
        assertEq(accessControl.isAdmin(user1), true);
        
        vm.prank(admin);
        accessControl.removeAdmin(user1);
        assertEq(accessControl.isAdmin(user1), false);
        
        vm.prank(conductor1);
        vm.expectRevert(IonicErrors.Unauthorized.selector);
        accessControl.removeAdmin(admin);
    }
    
    function testConductorStatusBasedOnTokenBalance() public {
        assertEq(conductors.getConductorId(user1) == 0, true);

        vm.startPrank(admin);
        IonicLibrary.Minter[] memory minters = new IonicLibrary.Minter[](1);
        minters[0] = IonicLibrary.Minter({minter: user1, reason: 1});
        ionicToken.authorizeMinters(minters);
        vm.stopPrank();

        vm.prank(user1);
        ionicToken.mint();

        assertEq(conductors.getConductorId(user1) != 0, true);

        vm.prank(user1);
        ionicToken.transferFrom(user1, admin, 3);
        assertEq(conductors.getConductorId(user1) == 0, true);
    }

    function testMultipleTokensStillConductor() public {
        vm.startPrank(admin);
        IonicLibrary.Minter[] memory minters = new IonicLibrary.Minter[](1);
        minters[0] = IonicLibrary.Minter({minter: admin, reason: 1});
        ionicToken.authorizeMinters(minters);
        ionicToken.mint();
        vm.stopPrank();

        assertEq(conductors.getConductorId(conductor1) != 0, true);
        assertEq(ionicToken.balanceOf(conductor1), 1);

        vm.prank(conductor1);
        ionicToken.transferFrom(conductor1, user1, 1);
        assertEq(conductors.getConductorId(conductor1) == 0, true);
        assertEq(conductors.getConductorId(user1) != 0, true);
    }
    
    function testOnlyAdminCanSetIonicToken() public {
        address newTokenAddress = address(0x999);
        
        vm.prank(admin);
        accessControl.setIonicToken(newTokenAddress);
        assertEq(accessControl.ionicToken(), newTokenAddress);
        
        vm.prank(conductor1);
        vm.expectRevert(IonicErrors.Unauthorized.selector);
        accessControl.setIonicToken(address(ionicToken));
    }
    
    function testOnlyAdminCanSetMonaToken() public {
        address newTokenAddress = address(0x888);
        
        vm.prank(admin);
        accessControl.setMonaToken(newTokenAddress);
        assertEq(address(accessControl.monaToken()), newTokenAddress);
        
        vm.prank(conductor1);
        vm.expectRevert(IonicErrors.Unauthorized.selector);
        accessControl.setMonaToken(address(monaToken));
    }
}