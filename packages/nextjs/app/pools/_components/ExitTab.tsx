import { TokenField } from "./TokenField";
import { GradientButton } from "~~/components/common";
import { type Pool } from "~~/hooks/balancer/types";

/**
 *
 */
export const ExitTab = ({ pool }: { pool: Pool }) => {
  console.log("pool", pool);
  return (
    <section>
      <TokenField
        label="BPT In"
        tokenSymbol={pool.symbol}
        value=""
        onAmountChange={() => console.log("amount changed")}
      />
      <div>
        <GradientButton onClick={() => console.log("query exit button!")} isDisabled={false}>
          Query Exit
        </GradientButton>
      </div>
    </section>
  );
};
