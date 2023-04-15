import Image from "next/image";

export function CryptoPunkImage({
  punkId,
  children,
}: {
  punkId: number;
  children?: React.ReactNode;
}) {
  return (
    <div
      className="relative"
      style={{
        backgroundColor: "#638596",
      }}
    >
      <Image
        className="aspect-square h-auto mx-auto w-full max-h-90 max-w-90"
        style={{
          imageRendering: "pixelated",
        }}
        src={`https://cryptopunks.app/public/images/cryptopunks/punk${punkId}.png`}
        alt={`Punk #${punkId}`}
        width={24}
        height={24}
        unoptimized
        priority
      />
      {children}
    </div>
  );
}
