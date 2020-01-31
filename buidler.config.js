// ES6 module imports via require
require("@babel/register");
// Libraries
const assert = require("assert");
const { providers, utils } = require("ethers");
// Helpers
const checkNestedObj = require("./scripts/helpers/nestedObjects/checkNestedObj")
  .default;
const getNestedObj = require("./scripts/helpers/nestedObjects/getNestedObj")
  .default;
const sleep = require("./scripts/helpers/async/sleep").default;

// ================================= BRE extension ==================================
extendEnvironment(bre => {
  bre.checkNestedObj = checkNestedObj;
  bre.getNestedObj = getNestedObj;
  bre.sleep = sleep;
});

// ================================= CONFIG =========================================
// Env Variables
require("dotenv").config();
const DEV_MNEMONIC = process.env.DEV_MNEMONIC;
const MAINNET_MNEMONIC = process.env.MAINNET_MNEMONIC;
const INFURA_ID = process.env.INFURA_ID;
assert.ok(DEV_MNEMONIC, "no mnenomic in process.env");
assert.ok(INFURA_ID, "no Infura ID in process.env");

// Defaults
const DEFAULT_NETWORK = "kovan";

module.exports = {
  defaultNetwork: DEFAULT_NETWORK,
  networks: {
    buidlerevm: {
      hardfork: "istanbul",
      contracts: [
        // BuidlerEVM
        "ActionBzxPtokenBurnToToken",
        "ActionBzxPtokenMintWithToken",
        "ActionERC20Transfer",
        "ActionERC20TransferFrom",
        "ActionKyberTrade",
        "ActionMultiMintForConditionTimestampPassed",
        "GelatoCore",
        "ConditionBalance",
        "ConditionKyberRateKovan",
        "ConditionTimestampPassed",
        // Testing
        "Action",
        "Core",
        "UserProxy"
      ]
    },
    mainnet: {
      // Standard
      accounts: { mnemonic: MAINNET_MNEMONIC },
      chainId: 1,
      gas: "auto",
      gasPrice: parseInt(utils.parseUnits("2", "gwei")), // 2 gwei
      gasMultiplier: 1.5,
      url: `https://mainnet.infura.io/v3/${INFURA_ID}`,
      // Custom
      addressBook: {
        EOA: {
          // Mainnet
          luis: "0x4B7363b8a7DaB76ff73dFbA00801bdDcE699F3A2"
        },
        erc20: {
          // Mainnet
          // Tokens
          DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
          "0x6B175474E89094C44Da98b954EedeAC495271d0F": "DAI",
          KNC: "0xdd974d5c2e2928dea5f71b9825b8b646686bd200",
          "0xdd974d5c2e2928dea5f71b9825b8b646686bd200": "KNC"
          // ==== BzX pTokens ====
          // Long
          /*dLETH2x: "0x934b43143e984052961EB46f5bDE633F33bCDB80",
          "0x934b43143e984052961EB46f5bDE633F33bCDB80": "dLETH2x",
          dLETH3x: "0x0015Cfd9722B43ac277f37887df14a00109fc689",
          "0x0015Cfd9722B43ac277f37887df14a00109fc689": "dLETH3x",
          dLETH4x: "0x0E5f87BDcD6285F930b6bbcC3E21CA9d985e12fE",
          "0x0E5f87BDcD6285F930b6bbcC3E21CA9d985e12fE": "dLETH4x",
          // Short
          dsETH: "0xD4Fd1467c867808dc7B393dBc863f34783F37d3E",
          "0xD4Fd1467c867808dc7B393dBc863f34783F37d3E": "dsETH",
          dsETH2x: "0x2EBfbCf2d67867a05BCAC0FbCA54019163253988",
          "0x2EBfbCf2d67867a05BCAC0FbCA54019163253988": "dsETH2x",
          dsETH3x: "0xB56EA362eA9B1D030213A47eAA452dFfd84CB5a2",
          "0xB56EA362eA9B1D030213A47eAA452dFfd84CB5a2": "dsETH3x",
          dsETH4x: "0x9486ac55ed81758787fcdda98e6Ce35b01CDBE72",
          "0x9486ac55ed81758787fcdda98e6Ce35b01CDBE72": "dsETH4x"*/
        },
        executor: {
          // Mainnet
          default: "0x4B7363b8a7DaB76ff73dFbA00801bdDcE699F3A2"
        },
        kyber: {
          // Mainnet
          ETH: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
          proxy: "0x818E6FECD516Ecc3849DAf6845e3EC868087B755"
        },
        userProxy: {
          // Mainnet
          luis: ""
        }
      },
      contracts: [
        // Mainnet
        "ActionBzxPtokenBurnToToken",
        "ActionBzxPtokenMintWithToken",
        "ActionERC20Transfer",
        "ActionERC20TransferFrom",
        "ActionKyberTrade",
        "GelatoCore",
        "ConditionBalance",
        "ConditionKyberRate",
        "ConditionTimestampPassed"
      ],
      deployments: {
        // ========== MAINNET ===========
        // === Actions ===
        // BzX
        ActionBzxPtokenBurnToToken:
          "0x43dFFE6f0C2029e397Fa47DD27587Ef6297660C3",
        ActionBzxPtokenMintWithToken:
          "0x080d3059b30D3B7EDffa1B0B9AE981f0Ce94168E",
        // erc20
        ActionERC20Transfer: "0x213719cD7c69DCA764E336bEb8D735DA01FD6c83",
        ActionERC20TransferFrom: "0x24b7b219E903d11489227c5Bed0718D90C03eBc2",
        // kyber
        ActionKyberTrade: "0xF829B506c378AaD11dB7Efe8d626cc7d0e015CBA",
        // ==== Gelato Core ===
        GelatoCore: "0x4E2Ca0093028C8401C93AaCcCaF59288CA6fb728",
        // === Conditions ===
        // balance
        ConditionBalance: "0x60621bf3F7132838b27972084eaa56E87395D44B",
        // kyber
        ConditionKyberRate: "0xD8eBB69Dc566E86eA6e09A15EBe6Fd9c65c4A698",
        // time
        ConditionTimestampPassed: "0x10A46c633adfe5a6719f3DBd2c162676779fE70B"
      }
    },
    kovan: {
      // Standard
      accounts: { mnemonic: MAINNET_MNEMONIC },
      chainId: 42,
      gasPrice: 1000000000, // 1 gwei
      url: `https://kovan.infura.io/v3/${INFURA_ID}`,
      // Custom
      addressBook: {
        EOA: {
          // Kovan
          luis: "0x203AdbbA2402a36C202F207caA8ce81f1A4c7a72",
          hilmar: "0xe2A8950bC498e19457BE5bBe2C25bC1f535C743e"
        },
        erc20: {
          // Kovan
          // Tokens
          DAI: "0xC4375B7De8af5a38a93548eb8453a498222C4fF2",
          "0xC4375B7De8af5a38a93548eb8453a498222C4fF2": "DAI",
          KNC: "0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2",
          "0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2": "KNC",
          // ==== BzX pTokens ====
          // Long
          dLETH2x: "0x934b43143e984052961EB46f5bDE633F33bCDB80",
          "0x934b43143e984052961EB46f5bDE633F33bCDB80": "dLETH2x",
          dLETH3x: "0x0015Cfd9722B43ac277f37887df14a00109fc689",
          "0x0015Cfd9722B43ac277f37887df14a00109fc689": "dLETH3x",
          dLETH4x: "0x0E5f87BDcD6285F930b6bbcC3E21CA9d985e12fE",
          "0x0E5f87BDcD6285F930b6bbcC3E21CA9d985e12fE": "dLETH4x",
          // Short
          dsETH: "0xD4Fd1467c867808dc7B393dBc863f34783F37d3E",
          "0xD4Fd1467c867808dc7B393dBc863f34783F37d3E": "dsETH",
          dsETH2x: "0x2EBfbCf2d67867a05BCAC0FbCA54019163253988",
          "0x2EBfbCf2d67867a05BCAC0FbCA54019163253988": "dsETH2x",
          dsETH3x: "0xB56EA362eA9B1D030213A47eAA452dFfd84CB5a2",
          "0xB56EA362eA9B1D030213A47eAA452dFfd84CB5a2": "dsETH3x",
          dsETH4x: "0x9486ac55ed81758787fcdda98e6Ce35b01CDBE72",
          "0x9486ac55ed81758787fcdda98e6Ce35b01CDBE72": "dsETH4x"
        },
        executor: {
          // Kovan
          default: "0x203AdbbA2402a36C202F207caA8ce81f1A4c7a72"
        },
        kyber: {
          // Kovan
          ETH: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
          proxy: "0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D"
        },
        userProxy: {
          // Kovan
          luis: "0x38CEEd828056934686d6A0Ead2EeC1e49849d9c5"
        }
      },
      contracts: [
        // Kovan
        "ActionBzxPtokenBurnToToken",
        "ActionBzxPtokenMintWithToken",
        "ActionERC20Transfer",
        "ActionERC20TransferFrom",
        "ActionKyberTradeKovan",
        "ActionMultiMintForConditionTimestampPassed",
        "GelatoCore",
        "ConditionBalance",
        "ConditionKyberRateKovan",
        "ConditionTimestampPassed"
      ],
      deployments: {
        // ========== KOVAN ===========
        // === Actions ===
        // BzX
        ActionBzxPtokenBurnToToken:
          "0x43dFFE6f0C2029e397Fa47DD27587Ef6297660C3",
        ActionBzxPtokenMintWithToken:
          "0x080d3059b30D3B7EDffa1B0B9AE981f0Ce94168E",
        // erc20
        ActionERC20Transfer: "0x213719cD7c69DCA764E336bEb8D735DA01FD6c83",
        ActionERC20TransferFrom: "0x24b7b219E903d11489227c5Bed0718D90C03eBc2",
        // kyber
        ActionKyberTradeKovan: "0xF829B506c378AaD11dB7Efe8d626cc7d0e015CBA",
        // ==== Gelato Core ===
        GelatoCore: "0x4E2Ca0093028C8401C93AaCcCaF59288CA6fb728",
        // === Conditions ===
        // balance
        ConditionBalance: "0x60621bf3F7132838b27972084eaa56E87395D44B",
        // kyber
        ConditionKyberRateKovan: "0xD8eBB69Dc566E86eA6e09A15EBe6Fd9c65c4A698",
        // time
        ConditionTimestampPassed: "0x10A46c633adfe5a6719f3DBd2c162676779fE70B"
      }
    },
    ropsten: {
      // Standard
      accounts: { mnemonic: DEV_MNEMONIC },
      chainId: 3,
      gasPrice: 20000000000, // 20 gwei
      url: `https://ropsten.infura.io/v3/${INFURA_ID}`,
      // Custom
      addressBook: {
        EOA: {
          // Ropsten
          luis: "0x203AdbbA2402a36C202F207caA8ce81f1A4c7a72",
          hilmar: "0xe2A8950bC498e19457BE5bBe2C25bC1f535C743e"
        },
        erc20: {
          // Ropsten
          DAI: "0xad6d458402f60fd3bd25163575031acdce07538d",
          "0xad6d458402f60fd3bd25163575031acdce07538d": "DAI",
          KNC: "0x4e470dc7321e84ca96fcaedd0c8abcebbaeb68c6",
          "0x4e470dc7321e84ca96fcaedd0c8abcebbaeb68c6": "KNC",
          MANA: "0x72fd6C7C1397040A66F33C2ecC83A0F71Ee46D5c",
          "0x72fd6C7C1397040A66F33C2ecC83A0F71Ee46D5c": "MANA",
          WETH: "0xbca556c912754bc8e7d4aad20ad69a1b1444f42d",
          "0xbca556c912754bc8e7d4aad20ad69a1b1444f42d": "WETH"
        },
        executor: {
          // Ropsten
          default: "0x203AdbbA2402a36C202F207caA8ce81f1A4c7a72"
        },
        kyber: {
          // Ropsten
          proxy: "0x818E6FECD516Ecc3849DAf6845e3EC868087B755"
        },
        userProxy: {
          // Ropsten
          luis: "0x1631B08A31Ecc1e125939002326E4b281E9eCd75"
        }
      },
      contracts: [
        // Ropsten
        "ConditionBalance"
      ],
      deployments: {
        // Ropsten
        ConditionBalance: "0xaFa77E70C22F5Ab583A9Eae6Dc7290e6264832Af"
      }
    }
  },
  solc: {
    version: "0.6.1",
    optimizer: { enabled: true, runs: 200 }
  }
};

// ================================= PLUGINS =========================================
usePlugin("@nomiclabs/buidler-ethers");

// ================================= TASKS =========================================
// task action function receives the Buidler Runtime Environment as second argument

// ============= ABI ============================
require("./scripts/buidler_tasks/abi/collection.tasks.abi");

// ============= BLOCK ============================
require("./scripts/buidler_tasks/block/collection.tasks.block");

// ============= BRE ============================
// BRE, BRE-CONFIG(:networks), BRE-NETWORK
require("./scripts/buidler_tasks/bre/collection.tasks.bre");

// ============= DEBUGGING ============================
require("./scripts/buidler_tasks/debugging/collection.tasks.debugging");

// ============= DEPLOY ============================
require("./scripts/buidler_tasks/deploy/task.deploy");

// ============= ERC20 ============================
require("./scripts/buidler_tasks/erc20/collection.tasks.erc20");

// ============== ETH =================================================================
task(
  "eth-balance",
  `Return or (--log) an [--address] ETH balance on [--network] (default: ${DEFAULT_NETWORK})`
)
  .addParam("address", "The account's address")
  .addFlag("log", "Logs return values to stdout")
  .setAction(async ({ address, log }, { ethers, network }) => {
    try {
      const balance = await ethers.provider.getBalance(address);
      if (log)
        console.log(`\n${utils.formatEther(balance)} ETH (on ${network.name})`);
      return balance;
    } catch (error) {
      console.error(error);
      process.exit(1);
    }
  });

task("eth-price", "Logs the etherscan ether-USD price", async () => {
  try {
    const etherscanProvider = new providers.EtherscanProvider();
    const ethUSDPrice = await etherscanProvider.getEtherPrice();
    console.log(`\nETH price in USD: ${ethUSDPrice}$\n`);
    return ethUSDPrice;
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
});

// ============== ETHERS ==============================================================
require("./scripts/buidler_tasks/ethers/collection.tasks.ethers");

// ============= GELATO ===============================================================
// _____ ACTIONS ______________________
require("./scripts/buidler_tasks/gelato/actions/collection.tasks.actions");
// _____ CORE ______________________
// Accounting, UserProxyManager, Minting, ...
require("./scripts/buidler_tasks/gelato/core/collection.gelato-core.tasks");
// _____ DAPPS ______________________
require("./scripts/buidler_tasks/gelato/dapps/collection.tasks.dapps");
// _____ Conditions ______________________
require("./scripts/buidler_tasks/gelato/conditions/collection.tasks.conditions");

// ============== INTERNAL HELPER TASKS ================================================
// encoding, naming ....
require("./scripts/buidler_tasks/internal/collection.internalTasks");
