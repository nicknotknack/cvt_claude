import { useReadContracts } from 'wagmi'
import { SALE_ADDRESS, CryptoVisionSaleABI } from '../config/contracts'

const saleContract = {
  address: SALE_ADDRESS,
  abi: CryptoVisionSaleABI,
} as const

export function useSaleInfo() {
  const { data, isLoading, refetch } = useReadContracts({
    contracts: [
      { ...saleContract, functionName: 'tokensRemaining' },
      { ...saleContract, functionName: 'totalTokensSold' },
      { ...saleContract, functionName: 'saleActive' },
      { ...saleContract, functionName: 'TOKENS_PER_ETH' },
    ],
    query: {
      refetchInterval: 10_000,
    },
  })

  return {
    tokensRemaining: data?.[0]?.result as bigint | undefined,
    totalTokensSold: data?.[1]?.result as bigint | undefined,
    saleActive: data?.[2]?.result as boolean | undefined,
    tokensPerEth: data?.[3]?.result as bigint | undefined,
    isLoading,
    refetch,
  }
}
