import Image from "next/image";

export function GroupHeader(props: { punkId: number }) {
  return (
    <header>
      <div style={{ color: "#85B4FD" }} className="font-bold mt-5 mb-2">
        CryptoPunks
      </div>
      <div className="flex text-white justify-between mb-8">
        <h1 className="text-2xl">CryptoPunk #{props.punkId}</h1>
        <Image src="/share.svg" alt="share" width={19} height={19.92} />
      </div>
    </header>
  );
}
