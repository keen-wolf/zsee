{

	#Dynamically get the windows size at each loop
	if (stty_lns_set == 0){ #preset in shell begion or not
		"tput lines"|getline lns; close("tput lines");
		stty_lines=lns+0;
	}else{
		stty_lines=stty_lns_set+0;
	}
	wlns=stty_lines-7;

	#check if is wide enough. now each col in showbuff occupy about 41 colums in screen
	"tput cols"|getline cls; close("tput cols");
	stty_cols=cls+0;

	#let go wrong once to refresh the "col"
	if(stty_lines_pre == stty_lines && stty_cols < (col+1)*40){
		print "The screen is too small , please expand the window longer or wider"
		next;
	}
	stty_lines_pre = stty_lines;

	#####################################################

	#reset display buffer for dynamic window resize
	delete showbuf

	print "";

	if(NR==1){
		nets="";
		for(i=1;i<=NF;i++){
			if(match($i,"net/([0-9a-zA-Z]+)",neti)){
				nets=nets","neti[1];
			}
		}
		nets=substr(nets,2);
	}

	if(NR<=2)next;

	split($0,g,"|");

	printf "@"g[1]"\t\t";

	if (col > 0){ #if enough space then make MEM same line with DATE
		print "#MEM:\tused  buff  cach  free";
		print "\t\t\t\t"g[2];
	}else{
		print ""
		print "#MEM:\tused  buff  cach  free";
		print g[2];
		print ""
		wlns--; #tune the winln for the extra line occupied by MEM
	}

	split(nets,n,",");
	split(g[3],net,":");
	printf "#NET(I/O):  "
	for(i=1;i<=length(n);i++){
		split(net[i],nn," ");
		printf n[i]"( "nn[1]" / "nn[2]" )   ";
	}
	print "";print "";

	#make dsk_name with same cut length

	split(dsks,h,",");split(g[8],t,":");
	lcpu=length(t);
	ldsk=length(h);

	for(i=1;i<=length(h);i++)
		if(ldname<length(h[i]))
			ldname=length(h[i]);
	ldname = ldname < 4 ? 4 : ldname;
	for(i=1;i<=length(h);i++){
		if(length(h[i])>5)
			h[i]=substr(h[i],1,2)"."substr(h[i],length(h[i])-1);
		h[i]=sprintf("%"ldname"s",h[i]);
	}


	#if mix, then add 2 lins for header of CPU in the overlap window, total lines should adds 1 for the summary line.
	#when to_mix be computed, we dont take the top headers(with 2lines) in count
	to_mix =  int((lcpu+1+wlns-1)/wlns)+int((ldsk+1+wlns-1)/wlns) > int((ldsk+1+lcpu+1+2+wlns-1)/wlns) ? 1 : 0	;
	#now set the display buf due to logical sequence. now we take the top headers included. so the window length is: wlns+2


##################for dsk show
	curr=0;
	for( i=1; i<=ldsk+1; i++ ){
		col = int(curr/(wlns+2));
		if( curr % (wlns+2) == 0){#arry subindex all starts from zero
			showbuf[curr++ % (wlns+2), col]="#DSK:      r     w    r/s    w/s  rqsz  util \t|"
			showbuf[curr++ % (wlns+2), col]="---------------------------------------------\t|"
		}

		if (i == ldsk+1){
			#dsk summary
			dsksum = sprintf("%"ldname"s:","ALL")
			for(tt=1;tt<=2;tt++)dsksum = dsksum""sprintf("%4dM ",bdd[tt]/1024/1024);
			for(tt=1;tt<=2;tt++)dsksum = dsksum""sprintf("%4d  ",ops[tt]/length(h));
			dsksum = dsksum""sprintf("%5d  ",rqsz/length(h));
			dsksum = dsksum""sprintf("%4d  ",util/length(h));

			showbuf[curr++ % (wlns+2), col]=dsksum"\t|";

			for(tt=1;tt<=2;tt++){bdd[tt]=0;ops[tt]=0;}
			rqsz = 0;
			util = 0;
			continue;
		}


		onedsk = h[i];

		j=1;
		split(g[3+j],ss,":");
		onedsk = onedsk" "ss[i];
		split(ss[i],bd);
		for(tt=1;tt<=2;tt++){
			bdd[tt]+=match(bd[tt],"[0-9]+k")?bd[tt]*1024:match(bd[tt],"[0-9]+M")?bd[tt]*1024*1024:bd[tt];
		}
		#print bdd[1],bdd[2];


		j=2;
		split(g[3+j],ss,":");
		onedsk = onedsk" "ss[i];
		split(ss[i],bd);
		for(tt=1;tt<=2;tt++){
			ops[tt]+=bd[tt];
		}
		#print ops[1],ops[2];

		j=3;
		split(g[3+j],ss,":");
		onedsk = onedsk"  "ss[i];
		rqsz+=ss[i];
		#print rqsz;


		j=4;
		split(g[3+j],ss,":");
		onedsk = onedsk"  "ss[i];
		util+=ss[i];
		#print util;

		showbuf[curr++ % (wlns+2), col] = onedsk"\t|";
	}


##################check the mix part

	if(to_mix){#add cpu header in middle
		showbuf[curr++ % (wlns+2), col]="\t\t\t\t\t\t|"
		showbuf[curr++ % (wlns+2), col]="#CPU:  usr sys idl wai hiq siq stl           \t|"
		showbuf[curr++ % (wlns+2), col]="---------------------------------------------\t|"
	}else{#if not to mix then padding to whole window,as upper()
		curr = int((curr+wlns+2-1)/(wlns+2))*(wlns+2);
	}


##################for CPU show

	for( i=1; i<=lcpu+1; i++ ){
		col = int(curr/(wlns+2));
		if( curr % (wlns+2) == 0){#arry subindex all starts from zero
			showbuf[curr++ % (wlns+2), col]="#CPU:  usr sys idl wai hiq siq stl         \t|"
			showbuf[curr++ % (wlns+2), col]="-------------------------------------------\t|"
		}

		if (i == lcpu+1){
			#CPU avg
			cpuavg = "AVG: "
			for(tt=1;tt<=length(c);tt++){cpuavg=cpuavg""sprintf("%3d ",cc[tt]/length(t));cc[tt]=0;}
			showbuf[curr++ % (wlns+2), col] = cpuavg" \t\t|";
			continue;
		}

		showbuf[curr++ % (wlns+2), col] = sprintf("%02d:  %s", i-1,t[i])"\t\t|";
		split(t[i],c);
		for(tt=1;tt<=length(c);tt++)cc[tt]+=c[tt];
	}

	##################showout



	for(i=0;i<wlns+2;i++){
		for(j=0;j<=col;j++)
			if((i,j) in showbuf){
				#printf i"-"j":";
				printf showbuf[i,j];
			}else{#This can only happen in the overlap region but wihout mix filled, so the width is same of the one disk, or the tail. and the blank no need to fill,or same as the CPU
				if(j==col)# The cpu width	- now the cpu and dsk take the same width for simple
					printf "\t\t\t\t\t\t|";
				else # the dsk width
					printf "\t\t\t\t\t\t|";
			}
		print ""
	}

for(i=0;i<=col;i++)
	printf "************************************************";


}

