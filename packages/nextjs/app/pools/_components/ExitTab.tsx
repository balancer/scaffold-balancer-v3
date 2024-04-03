export const ExitTab = () => {
  return (
    <section>
      <div className="mb-5">
        <div>
          <label>BPT In</label>
        </div>
        <div className="relative">
          <input type="number" className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10" />

          <div role="button" className="btn m-1 btn-accent rounded-lg absolute top-3 right-4">
            B-50DAI-50USDe
          </div>
        </div>
      </div>
      <div>
        <button className="btn btn-accent mt-3 w-full rounded-lg">Query Join</button>
      </div>
    </section>
  );
};
