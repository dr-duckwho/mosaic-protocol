export function LiveGroupDecorator(props: { punkId: number }) {
  return (
    <div
      className="absolute top-0 left-0 h-full w-full"
      style={{
        background:
          "linear-gradient(180deg, rgba(0, 0, 0, 0) 56.53%, rgba(18, 7, 20, 0.8) 91.62%)",
      }}
    >
      <div
        className="absolute left-5 top-6 text-white flex items-center justify-between py-1.5 px-3"
        style={{
          background:
            "linear-gradient(93.21deg, #6732FF 14.82%, #FA7F7F 91.44%)",
          borderRadius: 35,
        }}
      >
        <div className="font-bold">·</div>
        <div className="mx-1 font-bold text-base/5">Live</div>
        <div className="font-bold text-sm/5 mt-0.5">03:45:34</div>
      </div>
      <h3 className="absolute bottom-7 left-5 text-2xl font-medium text-white">
        CryptoPunk #{props.punkId}
      </h3>
    </div>
  );
}
