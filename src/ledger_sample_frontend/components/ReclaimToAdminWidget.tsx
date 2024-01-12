import React from "react";
import { useCanister } from "@connect2ic/react";
import { Principal } from '@dfinity/principal';
import { ledger_sample_backend } from "../../declarations/ledger_sample_backend";

interface ReclaimToAdminWidgetProps {
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

const ReclaimToAdminWidget: React.FC<ReclaimToAdminWidgetProps> = ({ onReclaimSuccess, onReclaimError }) => {
    const [authenticatedLedgerBackend, { error, loading }] = useCanister('ledger_sample_backend');
    const [adminPrincipal, setAdminPrincipal] = React.useState<string | null>(null);

    React.useEffect(() => {
        const fetchAdminPrincipal = async () => {
            try {
                const principal = await ledger_sample_backend.getAdminPrincipal() as Principal;
                if (principal) {
                    setAdminPrincipal(principal.toText());
                } else {
                    setAdminPrincipal('No admin principal found');
                }
            } catch (error) {
                console.error('Error fetching admin principal:', error);
            }
        };

        fetchAdminPrincipal();
    }, [ledger_sample_backend]);

    const handleReclaimToAdmin = async () => {
        if (authenticatedLedgerBackend && authenticatedLedgerBackend.reclaimICPToAdmin) {
            try {
                const result = await authenticatedLedgerBackend.reclaimICPToAdmin() as ReclaimResponse;
                // Assuming result is structured similarly to ReclaimResponse
                if ("ok" in result) {
                    console.log('Reclaim to Admin Success:', result.ok);
                    onReclaimSuccess?.(result.ok);
                } else {
                    console.error('Reclaim to Admin Error:', result.err);
                    onReclaimError?.(result.err);
                }
            } catch (error) {
                console.error('Reclaim to Admin Error:', error);
                onReclaimError?.((error as any).toString());
            }
        } else {
            console.error('Authenticated ledger backend is not available.');
            onReclaimError?.('Authenticated ledger backend is not available.');
        }
    };

    return (
        <div className="reclaim-to-admin-widget">
            <h3>Reclaim ICP to Admin</h3>
            <div>Admin Principal: {adminPrincipal}</div>
            <button onClick={handleReclaimToAdmin} disabled={loading}>Reclaim to Admin</button>
            {error && <p className="error">{error}</p>}
        </div>
    );
};

export default ReclaimToAdminWidget;