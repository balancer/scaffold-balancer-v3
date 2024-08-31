import {
  CheckCircleIcon,
  ExclamationCircleIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon,
} from "@heroicons/react/24/outline";

interface AlertProps {
  type: "error" | "warning" | "success" | "info"; // `type` is required
  showIcon?: boolean;
  children?: React.ReactNode; // `children` can be optional
}

const alertTypeMap = {
  error: { styles: "bg-error-tint border-error ", icon: <ExclamationCircleIcon className="w-6 h-6" /> },
  warning: { styles: "bg-warning-tint border-warning ", icon: <ExclamationTriangleIcon className="w-6 h-6" /> },
  success: { styles: "bg-success-tint border-success ", icon: <CheckCircleIcon className="w-6 h-6" /> },
  info: { styles: "bg-info-tint border-info ", icon: <InformationCircleIcon className="w-6 h-6" /> },
};

export const Alert: React.FC<AlertProps> = ({ children, type, showIcon = true }) => {
  const { styles, icon } = alertTypeMap[type];
  return (
    <div className={`${styles} border flex items-center gap-2 p-2 rounded-lg overflow-auto`}>
      {showIcon && <div>{icon}</div>}
      <div>{children}</div>
    </div>
  );
};
