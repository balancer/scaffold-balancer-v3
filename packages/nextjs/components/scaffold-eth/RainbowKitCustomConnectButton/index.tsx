"use client";

// @refresh reset
import { useRef, useState } from "react";
// import { Balance } from "../Balance";
import { AddressInfoDropdown } from "./AddressInfoDropdown";
import { AddressQRCodeModal } from "./AddressQRCodeModal";
import { NetworkOptions } from "./NetworkOptions";
import { WrongNetworkDropdown } from "./WrongNetworkDropdown";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { Address } from "viem";
import { useAutoConnect, useNetworkColor } from "~~/hooks/scaffold-eth";
import { useOutsideClick } from "~~/hooks/scaffold-eth/useOutsideClick";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { getBlockExplorerAddressLink } from "~~/utils/scaffold-eth";

/**
 * Custom Wagmi Connect Button (watch balance + custom design)
 */
export const RainbowKitCustomConnectButton = () => {
  const [selectingNetwork, setSelectingNetwork] = useState(false);
  useAutoConnect();
  const networkColor = useNetworkColor();
  const { targetNetwork } = useTargetNetwork();
  const dropdownRef = useRef<HTMLDetailsElement>(null);

  const closeDropdown = () => {
    setSelectingNetwork(false);
    dropdownRef.current?.removeAttribute("open");
  };
  useOutsideClick(dropdownRef, closeDropdown);

  return (
    <ConnectButton.Custom>
      {({ account, chain, openConnectModal, mounted }) => {
        const connected = mounted && account && chain;
        const blockExplorerAddressLink = account
          ? getBlockExplorerAddressLink(targetNetwork, account.address)
          : undefined;

        return (
          <>
            {(() => {
              if (!connected) {
                return (
                  <button className="btn btn-secondary rounded-xl" onClick={openConnectModal} type="button">
                    Connect Wallet
                  </button>
                );
              }

              if (chain.unsupported || chain.id !== targetNetwork.id) {
                return <WrongNetworkDropdown />;
              }

              return (
                <>
                  <div className="flex-col items-center hidden sm:flex">
                    <details ref={dropdownRef} className="dropdown dropdown-end leading-3">
                      <summary
                        onClick={() => setSelectingNetwork(true)}
                        tabIndex={0}
                        className="btn btn-secondary rounded-xl text-lg shadow-md dropdown-toggle gap-0 !h-auto"
                        style={{ color: networkColor }}
                      >
                        {chain.name}
                      </summary>
                      <ul
                        tabIndex={0}
                        className="dropdown-content menu z-[2] p-2 mt-2 bg-base-200 rounded-box gap-1 text-xl"
                      >
                        <NetworkOptions hidden={!selectingNetwork} />
                      </ul>
                    </details>
                  </div>
                  <AddressInfoDropdown
                    address={account.address as Address}
                    displayName={account.displayName}
                    ensAvatar={account.ensAvatar}
                    blockExplorerAddressLink={blockExplorerAddressLink}
                  />
                  <AddressQRCodeModal address={account.address as Address} modalId="qrcode-modal" />
                </>
              );
            })()}
          </>
        );
      }}
    </ConnectButton.Custom>
  );
};
