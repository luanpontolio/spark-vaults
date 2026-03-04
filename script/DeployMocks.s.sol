// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.21;

import { console, Script } from "forge-std/Script.sol";

import { UsdcVaultInstance } from "../deploy/UsdcVaultInstance.sol";
import { UsdcVaultL2Deploy } from "../deploy/UsdcVaultL2Deploy.sol";
import { MockERC20 }         from "../src/mocks/MockERC20.sol";
import { MockRateProvider }  from "../src/mocks/MockRateProvider.sol";
import { MockPSM }           from "../src/mocks/MockPSM.sol";

contract DeployMocks is Script {
    function run() external {
        string memory config = vm.readFile("./script/config-testnet.json");

        address deployer = vm.parseJsonAddress(config, ".deployer");
        address owner    = vm.parseJsonAddress(config, ".owner");

        console.log("Deploying mock PSM stack with the following parameters:");
        console.log("Deployer:", deployer);
        console.log("Owner:   ", owner);

        vm.startBroadcast();

        MockERC20 mockUsdc = new MockERC20("USD Coin",     "USDC",  6);
        MockERC20 mockSusds = new MockERC20("Staked USDS", "sUSDS", 18);
        MockRateProvider mockRp = new MockRateProvider();
        MockPSM mockPsm = new MockPSM(address(mockUsdc), address(mockSusds), address(mockRp));

        mockPsm.fund(address(mockUsdc),  1_000_000e6);
        mockPsm.fund(address(mockSusds), 1_000_000e18);

        UsdcVaultInstance memory instance = UsdcVaultL2Deploy.deploy(deployer, owner, address(mockPsm));

        vm.stopBroadcast();

        console.log("MockUSDC:             ", address(mockUsdc));
        console.log("MockSUSDS:            ", address(mockSusds));
        console.log("MockRateProvider:     ", address(mockRp));
        console.log("MockPSM:              ", address(mockPsm));
        console.log("USDC Vault Proxy:     ", instance.usdcVault);
        console.log("USDC Vault Impl:      ", instance.usdcVaultImp);
    }
}
