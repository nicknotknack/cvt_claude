import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { parseEther } from 'viem'
import { SALE_ADDRESS, CryptoVisionSaleABI } from '../config/contracts'

export function useBuyTokens() {
  const {
    writeContract,
    data: hash,
    isPending,
    error,
  } = useWriteContract()

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({ hash })

  function buyTokens(ethAmount: string) {
    writeContract({
      address: SALE_ADDRESS,
      abi: CryptoVisionSaleABI,
      functionName: 'buyTokens',
      value: parseEther(ethAmount),
    })
  }

  return {
    buyTokens,
    hash,
    isConfirming,
    isConfirmed,
    isPending,
    error,
  }
}
