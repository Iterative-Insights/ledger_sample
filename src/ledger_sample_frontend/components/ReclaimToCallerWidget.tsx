import React, { useState, useEffect } from "react"
import { useWallet, useCanister } from "@connect2ic/react"
import { ledger_sample_backend } from "../../declarations/ledger_sample_backend"; // Adjust the import path as necessary

interface ReclaimWidgetProps {
  onReclaimSuccess?: (response: string) => void;
  onReclaimError?: (error: string) => void;
}

// Define the expected response types
interface ReclaimSuccess {
  ok: string;
}

interface ReclaimError {
  err: string;
}
type ReclaimResponse = ReclaimSuccess | ReclaimError;

// const ReclaimWidget: React.FC = () => {
  const ReclaimToCallerWidget: React.FC<ReclaimWidgetProps> = ({ onReclaimSuccess, onReclaimError }) => {
  const [wallet] = useWallet()
  const [authenticatedLedgerBackend, { error, loading: ledgerBackendLoading }] = 
    useCanister('ledger_sample_backend');
    
    const handleReclaim = async () => {
      if (authenticatedLedgerBackend && authenticatedLedgerBackend.reclaimICP) {
        try {
          const result = await authenticatedLedgerBackend.reclaimICP() as ReclaimResponse;
          if ("ok" in result) {
            console.log('Reclaim Success:', result.ok);
            if (onReclaimSuccess) {
              onReclaimSuccess(result.ok);
            }
          } else {
            console.error('Reclaim Error:', result.err);
            onReclaimError?.(result.err);
          }
        } catch (error) {
          console.error('Reclaim Error:', error);
          if (onReclaimError) {
            onReclaimError((error as ReclaimError).err);
          }
        }
      } else {
        console.error('Authenticated ledger backend is not available.');
        if (onReclaimError) {
          onReclaimError('Authenticated ledger backend is not available.');
        }
      }
    };

  return (
    <div className="reclaim-to-caller-widget">
      {wallet ? (
        <>
          <h3>Reclaim ICP for: {wallet.principal?.toString()}</h3>
          <button onClick={handleReclaim}>Reclaim</button>
        </>
      ) : (
        <p className="reclaim-to-caller-widget-disabled">Connect with a wallet to access this example</p>
      )}
    </div>
  )
};

export default ReclaimToCallerWidget;