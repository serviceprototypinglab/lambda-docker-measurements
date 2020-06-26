import sys
import yaml
from distutils import util

BYTESINMB = 1048576
MBINGB = 1024
MSINS = 1000

faascc = yaml.load(open("calculator/faascc.simplified.yaml").read(), Loader=yaml.FullLoader)

def ceildiv(x, d):
	return (x + d - 1) // d

class ProviderCalculator():
    def __init__(self, providername):
        self.setProvider(providername)

    def setProvider(self, providername):
        self.provider = providername
        self.faasccnode = self.loadYAML(providername)

    def loadYAML(self, providername):
        for node in faascc:
            if node['name'] == providername:
                return node
        
        return {}

    def getTimeGranularity(self):
        return self.faasccnode['timegranularity'] * MSINS
    
    def getMinimumMemory(self):
        return self.faasccnode['memory']['min']

    def getMaximumMemory(self):
        return self.faasccnode['memory']['max']

    def getMemoryGranularity(self):
        return self.faasccnode['memory']['granularity']

    def getPricePerCall(self):
        return self.faasccnode['pricecall']

    def getComputePrice(self):
        return self.faasccnode['priceload']

    def getFreeTierCompute(self):
        return self.faasccnode['contingentload']

    def getFreeTierCalls(self):
        return self.faasccnode['contingentcalls']

    def calculateCost(self, nrequests, duration, memory, free):
        print(f"Calculating price for a {self.provider} function with {nrequests} monthly requests, running for {duration}ms each time, needing {memory} bytes of memory; and {'' if free else 'not'} taking into account the free tier")

        cost = self._getMonthlyComputeCharges(nrequests, duration, memory, free) + self._getMonthlyRequestCharges(nrequests, free)

        print(f"The monthly cost is ${cost:.2f}")

    def _getMonthlyComputeCharges(self, nrequests, duration, memory, free):
        awsduration = ceildiv(duration, self.getTimeGranularity()) * self.getTimeGranularity() / MSINS
        
        auxmem = ceildiv(memory, BYTESINMB)
        auxmem = min(max(auxmem, self.getMinimumMemory()), self.getMaximumMemory())
        auxmem = max(auxmem - self.getMinimumMemory(), 0)
        memorymult = ceildiv(auxmem, self.getMemoryGranularity())
        awsmemory = self.getMinimumMemory() + memorymult * self.getMemoryGranularity()

        print(f"{self.provider} assigned {awsmemory}MB and {awsduration}s to the function")

        total = nrequests * awsduration * awsmemory / MBINGB

        if free:
            total = max(total - self.getFreeTierCompute(), 0)

        return total * self.getComputePrice()
    
    def _getMonthlyRequestCharges(self, nrequests, free):
        total = nrequests

        if free:
            total = max(total - self.getFreeTierCalls(), 0)
        
        return total * self.getPricePerCall()     

if __name__ == "__main__":
    calculator = ProviderCalculator("AWS Lambda")
    calculator.calculateCost(int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), bool(util.strtobool(sys.argv[4])))


