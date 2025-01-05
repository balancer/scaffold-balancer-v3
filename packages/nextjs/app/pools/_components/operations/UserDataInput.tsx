import { formatToHex } from "~~/utils/";

export const UserDataInput = ({ onChange, value }: { onChange: (userData: string) => void; value: string }) => {
  return (
    <div>
      <div className="flex justify-between">
        <div className="font-bold ml-2 mb-1">User Data</div>
        <div className="mr-2 text-neutral-400">{formatToHex(value)}</div>
      </div>
      <input
        className="input shadow-inner rounded-lg bg-base-300 w-full"
        value={value}
        onChange={e => onChange(e.target.value)}
      />
    </div>
  );
};
