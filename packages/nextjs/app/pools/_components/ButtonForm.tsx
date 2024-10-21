import { TransactionButton } from "./operations/";

export const ButtonForm = ({ title, buttons, Footer }: { title: string; buttons?: any[]; Footer?: any }) => {
  return (
    <div className="w-full flex flex-col shadow-lg">
      <div className="bg-base-200 p-5 rounded-lg">
        <h5 className="text-xl font-bold mb-3">{title}</h5>
        <div className="bg-neutral rounded-lg">
          <div className="border-base-300 border-b p-4">
            {buttons?.map(e => (
              <TransactionButton
                key={e.label}
                label={e.label}
                onClick={e.onClick}
                className="mb-2"
                isFormEmpty={e.isFormEmpty}
              />
            ))}
            {Footer && <Footer />}
          </div>
        </div>
      </div>
    </div>
  );
};
