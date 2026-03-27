interface TransactionStatusProps {
  hash: `0x${string}` | undefined
  isConfirming: boolean
  isConfirmed: boolean
  error: Error | null
}

export function TransactionStatus({
  hash,
  isConfirming,
  isConfirmed,
  error,
}: TransactionStatusProps) {
  if (!hash && !error) return null

  return (
    <div className="mt-4 space-y-2">
      {isConfirming && (
        <div className="flex items-center gap-2 text-yellow-400 text-sm">
          <div className="w-4 h-4 border-2 border-yellow-400 border-t-transparent rounded-full animate-spin" />
          Waiting for confirmation...
        </div>
      )}

      {isConfirmed && hash && (
        <div className="text-green-400 text-sm">
          <p className="font-medium mb-1">Transaction confirmed!</p>
          <p className="text-cyan-400 break-all text-xs">
            Tx: {hash.slice(0, 6)}...{hash.slice(-4)}
          </p>
        </div>
      )}

      {error && (
        <div className="text-red-400 text-sm">
          <p className="font-medium">Transaction failed</p>
          <p className="text-red-400/70 text-xs mt-1 break-all">
            {error.message.length > 200
              ? error.message.slice(0, 200) + '...'
              : error.message}
          </p>
        </div>
      )}
    </div>
  )
}
