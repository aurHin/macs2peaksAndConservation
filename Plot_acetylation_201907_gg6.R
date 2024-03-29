library(data.table)
library(ggplot2)
library(plyr)

y_limit<-0.07
colWidth<-0.7
pltWidth<-9 #in cm
pltHeight<-9 #in cm

fileForTesting<-"/Users/Hintermann/Desktop/LAB/ChIP/conservedSeqAndAc_mm_gg_PT_skin/B_PT_WP_Skin_CTCF/H3K27ac_mm10/macs2_toPlot/H3K27ac_WP_E125_macs2narrowPeak_noTSS_nonBrain_sub_ConservationColumns.bed"
regionsForQuantif<-commandArgs(T)[2]
regionsDF<-read.table(regionsForQuantif,sep="\t",stringsAsFactors=T)
terminal<-"Y"

if (terminal=="Y"){
  #macs2 peak file
  arg1<-commandArgs(T)[1]
}else{
  arg1<-fileForTesting
}

message("\n\n########\n######\nPlot data from file: ")
print(basename(arg1))
message(paste0("On regions:\n"),paste(regionsDF$V4,collapse="\n"))

tbl_toPlot<-read.csv(arg1,sep="\t",header=F,stringsAsFactors=T)
if(dim(tbl_toPlot)[2]==5){
  tbl_toPlot<-tbl_toPlot[,c(1,2,3,5)]
  colnames(tbl_toPlot)[4]<-"V4"
}
tbl_toPlot$xAxis<-NA
tbl_toPlot$regionLength<-NA

message("\n\nAdd region names and region sizes to table.")
for(reg in regionsDF$V4){
  RegOfInt<-regionsDF[regionsDF$V4==reg,]
  RegInterval<-c(RegOfInt$V2:RegOfInt$V3)
  chromosome<-as.character(RegOfInt$V1)
  #conditionToBeInReg<-tbl_toPlot$V1==RegOfInt$V3&tbl_toPlot$V2%in%RegInterval&tbl_toPlot$V3%in%RegInterval
  tbl_toPlot$xAxis[tbl_toPlot$V1==chromosome&tbl_toPlot$V2%in%RegInterval&tbl_toPlot$V3%in%RegInterval]<-reg
  tbl_toPlot$regionLength[tbl_toPlot$V1==chromosome&tbl_toPlot$V2%in%RegInterval&tbl_toPlot$V3%in%RegInterval]<-RegOfInt$V3-RegOfInt$V2
  }

#message(paste0("Keep only elements  with start and end included regions coordinates.\nNumber of peaks analyzed: ",))
tbl_toPlot<-tbl_toPlot[tbl_toPlot$xAxis%in%regionsDF$V4,]
#print(dim(tbl_toPlot)[1])
tbl_toPlot$V4<-factor(tbl_toPlot$V4, levels = c("noCNSoverlap","CNSoverlap"))
#print(head(tbl_toPlot))

outdir<-paste0(dirname(arg1),"/plots/")
dir.create(outdir,showWarnings = F)
pltName<-gsub(".bed",paste0("yaxis",y_limit,"_plottedData.png"),basename(arg1))
tblName<-gsub(".bed",paste0("yaxis",y_limit,"_plottedData.bed"),basename(arg1))

message("Plotting")

if(length(grep("resize",pltName))>0){
  peakSize<-"resized peaks"
}else{
  peakSize="original peaks"
  }

if(length(grep("PT",pltName))>0){
  tissue<-"PT"
}
if(length(grep("Skin",pltName))>0){
  tissue<-"Skin"
}
print(head(tbl_toPlot))

labsTitle<-paste0("macs2 H3K27ac\n",peakSize,"\n",tissue," minus Brain")
print(tbl_toPlot$V4)
plt<-ggplot(tbl_toPlot,aes(x=tbl_toPlot$xAxis,y=(tbl_toPlot$V3-tbl_toPlot$V2)/tbl_toPlot$regionLength,fill=tbl_toPlot$V4,width=colWidth))+geom_bar(stat ="identity")+theme_bw()+labs(title=labsTitle, x= " ",y ="[acetylated_bp/total_bp]", fill=" ")+coord_cartesian(ylim = c(0,y_limit))
dfData<-ggplot_build(plt)$plot$data
write.table(ggplot_build(plt)$plot$data,paste0(outdir,tblName), row.names = F,col.names = F,sep="\t",quote = F)
ggsave(paste0(outdir,pltName),width = pltWidth,height=pltHeight,units="cm")
message(paste0("Plot and plotted data saved under: ",outdir,pltName))

