import React, { useState } from "react";
import { useCanister } from "@connect2ic/react";
import { Result } from "../../declarations/ledger_sample_backend/ledger_sample_backend.did"

const ClearAllDepositsWidget: React.FC = () => {
    const [authenticatedLedgerSampleBackend, { error, loading }] = useCanister('ledger_sample_backend');
    const [isClearing, setIsClearing] = useState(false);

    const handleClearAllDeposits = async () => {
        if (authenticatedLedgerSampleBackend && authenticatedLedgerSampleBackend.clearAllDeposits) {
            setIsClearing(true);
            try {
                const result = await authenticatedLedgerSampleBackend.clearAllDeposits() as Result;
                if ("ok" in result) {
                console.log('Clear All Deposits:', result.ok);
                } else {
                    console.error('Clear All Deposits error:', result.err)
                }
                // Handle success, update UI, etc.
            } catch (error) {
                console.error('Clear All Deposits Error:', error);
                // Handle the error, show message to user, etc.
            }
            setIsClearing(false);
        } else {
            console.error('Authenticated ledger backend is not available.');
            // Handle the unavailable backend, show message to user, etc.
        }
    };

    return (
        <div className="clear-all-deposits-widget">
            <h3>Clear All Deposits</h3>
            <button
                onClick={handleClearAllDeposits}
                disabled={isClearing}
                style={{ opacity: loading ? 0.5 : 1 }}
            >
                Clear All Deposits
            </button>
            {error && <p className="error">{error}</p>}
        </div>
    );
};

export default ClearAllDepositsWidget;