// Define the props interface for easier type checking and autocomplete
interface QueryResultsProps {
  title: string; // The title of the query result section
  children: React.ReactNode; // The dynamic content passed to the component
}

export const QueryResults: React.FC<QueryResultsProps> = ({ title, children }) => {
  return (
    <div>
      <h5 className="mt-5 mb-1 ml-2">{title}</h5>
      <div className="bg-[#FCD34D40] border border-amber-400 rounded-lg p-5">{children}</div>
    </div>
  );
};
