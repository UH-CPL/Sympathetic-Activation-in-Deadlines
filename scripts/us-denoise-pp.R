myfilter<-function(decay,len){
  half = len/2
  y=c()
  for(i  in 1:half){
    y = c(y,exp(-decay*i))
  }
  count = 1
  
  y1   = rev(y)
  c(y,y1)
}

remove_noise = function (DataSignal, removeImpluse, lowpassDecayFreq, samplePerSecond){
  lowpassDecayValue = 0
  if(missing(samplePerSecond)) {
    samplePerSecond = 1
  }
  if(!missing(lowpassDecayFreq)) {
    lowpassDecayValue = samplePerSecond * 1/(length(DataSignal) * lowpassDecayFreq)
  } else {
    lowpassDecayValue = samplePerSecond * 0.01
  }
  if(missing(removeImpluse)) {
    removeImpluse = 1
  }
  #Get mean
  DClevel  = mean(DataSignal)
  
  #1)--------Remove Impluse noise---------------------------------- 
  if (removeImpluse == 1) {
    sizeOf_Temp = length(DataSignal) #get size of array Temp
    
    TempNR = DataSignal
    
    tempV = 0
    for(i in 1:(sizeOf_Temp-1)){
      tempV = tempV + abs(TempNR[i] - TempNR[i+1])
    }
    
    tempV = tempV/(sizeOf_Temp-1)
    # print(paste(sizeOf_Temp, tempV))
    for(i in 2:sizeOf_Temp){
      diff = abs(TempNR[i] - TempNR[i-1])
      
      # print(paste(diff, tempV))
      
      if(diff > tempV){
        if(TempNR[i] < TempNR[i-1]){
          TempNR[i] = TempNR[i-1]-tempV
        }else{
          TempNR[i] = TempNR[i-1]+tempV
        }
      }
    }
    DataSignal = TempNR            #impluse noise removed data
  }
  
  #2)-----------Take FFT----------------------------------
  #Ensure that shift will not affect the stability of the scheme By Gibbs phenomenon 
  
  Temp = DataSignal
  sizeOf_Temp = length(Temp)
  alpha = 0.5*(Temp[1] - Temp[sizeOf_Temp])
  beta  = 0.5*(Temp[1] + Temp[sizeOf_Temp])
  TempU = c()
  
  for(i in 1:sizeOf_Temp){
    TempU = c(TempU,Temp[i] - ((alpha*cos(pi*i/sizeOf_Temp) + beta)))
  }
  
  TempNew = c(TempU,rev(TempU))
  TempNew = t(TempNew)
  
  # Zero padding
  sizeOf_Temp = length(TempNew)
  sizeOf_fft = 2^(floor(log2(sizeOf_Temp)) + 1)
  TempNew = c(TempNew,rep(0,(sizeOf_fft-length(TempNew))))
  Tfft = fft(TempNew)/sizeOf_fft
  #print(Tfft)
  
  #3)-----------Create Lowpass filter---------------------------------- 
  filter = myfilter(lowpassDecayValue,sizeOf_fft)
  
  #4)-----------Apply Lowpass filter---------------------------------- 
  Tnr = Tfft*t(t(filter))
  
  TreconIM = fft(Tnr,inverse=T)
  NR_Signal = Re(TreconIM[1:length(Temp)])
  
  #5)-----------Add mean to corresponding temperature array---------------------------------- 
  sizeOf_Temp = length(Temp)
  for(i in 1:sizeOf_Temp){
    NR_Signal[i] = NR_Signal[i] + (alpha*cos(pi*i/sizeOf_Temp) + beta);
  }
  return(NR_Signal)
}
