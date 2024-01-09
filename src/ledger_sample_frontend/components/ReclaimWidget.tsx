import React from 'react';

interface ReclaimWidgetProps {
  onReclaim: () => Promise<void>;
}

const ReclaimWidget : React.FC<ReclaimWidgetProps> = ({ onReclaim }) => {
  const handleReclaim = async () => {
    await onReclaim();
  };

  return (
    <div>
      <h2>Reclaim ICP</h2>
      <button onClick={handleReclaim}>Reclaim</button>
    </div>
  );
};

export default ReclaimWidget;