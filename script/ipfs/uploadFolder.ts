import PinataClient, { PinataPinOptions } from "@pinata/sdk";
import { PinataConfig } from "@pinata/sdk/src";
import path from "path";

const pinataConfig: PinataConfig = {
  pinataApiKey: process.env.PINATA_API_KEY,
  pinataSecretApiKey: process.env.PINATA_API_SECRET,
  pinataJWTKey: process.env.PINATA_JWT,
};

const METADATA_PATH = path.join(__dirname, "metadata", "img_0001_test", "/");

async function main(sourcePath: string) {
  const options: PinataPinOptions = {
    pinataMetadata: {
      name: "upload_with_script_test_1",
    },
    pinataOptions: {
      cidVersion: 0,
    },
  };

  const pinata = new PinataClient(pinataConfig);
  pinata
    .pinFromFS(sourcePath, options)
    .then((result) => {
      console.log(result);
    })
    .catch((err) => {
      console.log(err);
    });
}

main(METADATA_PATH).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
