import { useState } from 'react';
import config from '../config';

function VerifyProofPage() {
  const [proof, setProof] = useState('');
  const [vk, setVk] = useState('');
  const [publicInputs, setPublicInputs] = useState('');
  const [verificationResult, setVerificationResult] = useState<boolean | null>(null);

  const handleVerifyProof = () => {
    const publicInputsArray = publicInputs.split(',').map(s => s.trim());

    fetch(`${config.proofServiceUrl}/verify-proof`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ 
        proof,
        vk,
        public_inputs: publicInputsArray,
      }),
    })
      .then(response => response.json())
      .then(data => setVerificationResult(data));
  };

  return (
    <div>
      <h2>Verify a Proof</h2>
      <textarea
        value={proof}
        onChange={e => setProof(e.target.value)}
        placeholder="Enter the proof (base64 encoded)"
      />
      <textarea
        value={vk}
        onChange={e => setVk(e.target.value)}
        placeholder="Enter the verifying key (base64 encoded)"
      />
      <input
        type="text"
        value={publicInputs}
        onChange={e => setPublicInputs(e.target.value)}
        placeholder="Enter public inputs (comma-separated)"
      />
      <button onClick={handleVerifyProof}>Verify Proof</button>

      {verificationResult !== null && (
        <div>
          <h3>Verification Result:</h3>
          <p>{verificationResult ? 'Valid' : 'Invalid'}</p>
        </div>
      )}
    </div>
  );
}

export default VerifyProofPage;
