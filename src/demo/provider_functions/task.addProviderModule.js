import { task } from "@nomiclabs/buidler/config";
import { defaultNetwork } from "../../../buidler.config";
import { utils, constants } from "ethers";

export default task(
  "gelato-add-provider-module",
  `Sends tx to GelatoCore.addProviderModule() on [--network] (default: ${defaultNetwork})`
)
  .addOptionalParam(
    "modulename",
    "Gelato Provider Module name (Options: GelatoUserProxy, GnosisSafe or DSProxy)"
  )
  .addOptionalParam("moduleaddress", "Gelato Provider Module address")
  .addOptionalParam("gelatocoreaddress", "Gelato Core address")
  .addFlag("log", "Logs return values to stdout")
  .setAction(async ({ modulename, moduleaddress, log, gelatocoreaddress }) => {
    try {
      const provider = getProvider();
      const providerAddress = await provider.getAddress();

      const gelatoCore = await run("instantiateContract", {
        contractname: "GelatoCore",
        contractaddress: gelatocoreaddress,
        deployments: true,
        signer: provider,
        write: true,
      });

      let providerModuleAddress;

      if (modulename && !moduleaddress) {
        let providerModule;
        switch (modulename) {
          case "GelatoUserProxy":
            providerModule = "ProviderModuleGelatoUserProxy";
            break;
          case "GnosisSafe":
            providerModule = "ProviderModuleGnosisSafeProxy";
            break;
          case "DSProxy":
            providerModule = "ProviderModuleDSProxy";
            break;
          default:
            throw Error(
              "Choose either: GelatoUserProxy, GnosisSafe or DSProxy as a modulename"
            );
        }
        providerModuleAddress = await run("bre-config", {
          deployments: true,
          contractname: providerModule,
        });
      } else if (!modulename && moduleaddress) {
        providerModuleAddress = moduleaddress;
      } else throw Error("Either provide modulename or moduleaddress");

      console.log(`
          \n Provider:                          ${providerAddress}\
          \n Whitelisting module for proxy:     ${modulename}\n
          \n Address of module to whitelist:    ${providerModuleAddress}\n
      `);

      // GelatoCore contract call from provider account
      const tx = await gelatoCore.addProviderModules([providerModuleAddress]);

      const etherscanLink = await run("get-etherscan-link", {
        txhash: tx.hash,
      });
      console.log(`Link to transaction: \n ${etherscanLink}\n`);
      await tx.wait();
      console.log(`✅ Tx mined`);
      return `✅ Tx mined`;
    } catch (error) {
      console.error(error, "\n");
      console.log(`❌ Tx failed`);
      process.exit(1);
    }
  });
