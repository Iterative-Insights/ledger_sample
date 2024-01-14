import React, { useState, useEffect } from "react"
import { useWallet, useCanister } from "@connect2ic/react"
import { ledger_sample_backend } from "../../declarations/ledger_sample_backend"; // Adjust the import path as necessary
import { Result } from "../../declarations/ledger_sample_backend/ledger_sample_backend.did";

interface ReclaimToCallerWidgetProps {
  afterReclaim: (response: string) => void;
}

const ReclaimToCallerWidget: React.FC<ReclaimToCallerWidgetProps> = ({ afterReclaim }) => {
  const [wallet] = useWallet()
  const [authenticatedLedgerSampleBackend, { error, loading: ledgerBackendLoading }] =
    useCanister('ledger_sample_backend');
  const [isReclaiming, setIsReclaiming] = useState(false);

  const handleReclaim = async () => {
    if (authenticatedLedgerSampleBackend && authenticatedLedgerSampleBackend.reclaimICP) {
      try {
        setIsReclaiming(true);
        const result = await authenticatedLedgerSampleBackend.reclaimICP() as Result;
        if ("ok" in result) {
          console.log('Reclaim Success:', result.ok);
          afterReclaim(result.ok);
        } else {
          console.error('Reclaim Error:', result.err);
          afterReclaim(result.err);
        }
      } catch (error) {
        console.error('Reclaim Error:', error);
        afterReclaim(error instanceof Error ? error.message : String(error));
      } finally {
        setIsReclaiming(false);
      }
    } else {
      console.error('Authenticated ledger backend is not available.');
      afterReclaim('Authenticated ledger backend is not available');
    }
  };

  return (
    <div className="reclaim-to-caller-widget">
      {wallet ? (
        <>
          <h3>Reclaim ICP for: {wallet.principal?.toString()}</h3>
          <button onClick={handleReclaim} disabled={isReclaiming} style={{ backgroundColor: isReclaiming ? 'grey' : 'initial' }}>
            {isReclaiming ? 'Reclaiming Your ICP...' : 'Reclaim Your ICP'}
          </button>
        </>
      ) : (
        <p className="reclaim-to-caller-widget-disabled">Connect with a wallet to access this example</p>
      )}
    </div>
  )
};

export default ReclaimToCallerWidget;