#!/bin/bash

main_directory=`pwd`
pdb_dir="$main_directory/data/pdb"
rsa_dir="$main_directory/data/rsa"
chain_dir="$main_directory/data/chain"
contact_dir="$main_directory/data/contact"
surface_dir="$main_directory/data/surface"
patch_dir="$main_directory/data/patch"
patch_abs_dir="$main_directory/data/patch/abs"
patch_contact_dir="$main_directory/data/patch/contact"
patch_psaia_dir="$main_directory/data/patch/psaia"
CA_atom_dir="$main_directory/data/CA_atom"

#create directory: workspace


#create subdirectories
cd data
mkdir rsa
mkdir chain
mkdir contact
mkdir surface
mkdir patch
mkdir patch/abs
mkdir patch/contact
mkdir patch/psaia
mkdir CA_atom


#create files: rsa

for i in $(ls $pdb_dir);do
	temp=$(echo ${i%.*})
	naccess $pdb_dir/$i
	cp ${temp}.rsa $rsa_dir
	rm ${temp}.asa
	rm ${temp}.log
	rm ${temp}.rsa
done

#create files: chain

for i in $(ls $pdb_dir);do
	temp=$(echo ${i%.*})
	cat ${pdb_dir}/$i | grep ^[A].* >${temp}_atom.txt
	sed -i '/AUTHOR/d' ${temp}_atom.txt
	awk '{if(!a[$5]++)print $5}' ${temp}_atom.txt >${chain_dir}/${temp}_chains.txt
	for chain in $(cat ${chain_dir}/${temp}_chains.txt);do
		case "$chain" in
			[A-Z]) 
			;;
			*)
			sed -i "/$chain/d" ${chain_dir}/${temp}_chains.txt
			;;
		esac
	done
	#cp ${temp}_atom.txt $CA_atom
	####
	#for j in $(cat ${chain_dir}/${temp}_chains.txt);do
	#	cat ${temp}_atom.txt | awk '$3=="CA" && $5=="${j}" {print $0}' >${CA_atom_dir}/${temp}_${j}_CA.txt
	#done
	####
	rm ${temp}_atom.txt

done
	
#calculate contact
for i in $(ls ${pdb_dir});do
	temp=$(echo ${i%.*})
	for j in $(cat ${chain_dir}/${temp}_chains.txt);do
		Qcontacts -i ./pdb/${i} -prefOut ./contact/${temp}_$j -c1 $j -c2 $j
		rm ./contact/${temp}_$j-by-atom.vor
	done
done

#calculate surface
#extract relative accessibilities
cd rsa
for i in $(ls ${rsa_dir});do
	#temp: 1acb
	temp=$(echo ${i%.*})
	cp $i ${i}.bak
	lines=$(sed -n '$n' ${temp}.rsa)
	sed -i '$d' ${temp}.rsa.bak
	sed -i '$d' ${temp}.rsa.bak
	sed -i '$d' ${temp}.rsa.bak
	sed -i '$d' ${temp}.rsa.bak
	sed -i '$d' ${temp}.rsa.bak
	sed -i "1,4d" ${temp}.rsa.bak
	awk '{print $3,$4,$6}' ${temp}.rsa.bak >${surface_dir}/${temp}_rel.txt
	awk '{print $3,$2,$4,$5}' ${temp}.rsa.bak >${rsa_dir}/${temp}_abs.txt
	# divide abs by chain
	for j in $(cat ${chain_dir}/${temp}_chains.txt);do
		cat ${rsa_dir}/${temp}_abs.txt | grep ^[${j}].* >${rsa_dir}/${temp}_${j}_abs.txt
	done
	
	cat ${surface_dir}/${temp}_rel.txt | awk '$3>15{print $0}' >${surface_dir}/${temp}_surface.txt
	
	#rm ${temp}.rsa.bak
	
done
#extract surface, which larger than 15%
cd ..
cd surface

for i in $(ls ${surface_dir});do
	temp=$(echo ${i%_*})
	
	for j in $(cat ${chain_dir}/${temp}_chains.txt);do
		cat ${temp}_surface.txt | grep ^[${j}].* >${temp}_${j}_surface.txt
	done
done

#divide patches and delete unsurface patches
cd ..
for i in $(ls ${contact_dir});do
	#temp:  1acb_E-by
	#temp1: 1acb_E
	temp=$(echo ${i%-*})
	temp1=$(echo ${temp%-*})
	awk '{if(!a[$6]++) print $6}' ${contact_dir}/${i} >${contact_dir}/${temp}-res.txt
	for j in $(cat ${contact_dir}/${temp}-res.txt);do
		cat ${contact_dir}/${temp}-res.vor | awk '$6=='$j'{print $0}' >${patch_dir}/${temp}_patch_${j}.txt
		value=0
		
		for l in $(awk '{print $2}' ${patch_dir}/${temp}_patch_${j}.txt);do
			#echo $l
			res=$(awk '{print $2}' ${surface_dir}/${temp1}_surface.txt)
			#echo $res
			if ( echo ${res} | grep -q $l);then
				value=1
			fi				 
		done

		####
		if [ $value = 1 ];then
			#patch_abs
			for k in $(awk '{print $2}' ${patch_dir}/${temp}_patch_${j}.txt);do
				cat ${rsa_dir}/${temp1}_abs.txt | awk '$3=='$k'{print $0}' >>${patch_abs_dir}/${temp1}_patch_${j}.txt
			done
		
			#patch_contact	
			for m in $(awk '{print $2}' ${patch_dir}/${temp}_patch_${j}.txt);do
				for n in $(awk '{print $2}' ${patch_dir}/${temp}_patch_${j}.txt);do
					if [ $n -ne $m ];then
						cat ${contact_dir}/${temp}-res.vor | awk '$2=='$m' && $6=='$n' {print $0}' >>${patch_contact_dir}/${temp1}_patch_${j}.txt
					fi
					####
					if [ $n = $m ];then
						cat ${contact_dir}/${temp}-res.vor | awk '$2=='$m' && $6=='$n' {print $0}' >>${patch_contact_dir}/${temp1}_patch_${j}.txt
						cat ${contact_dir}/${temp}-res.vor | awk '$2=='$m' && $6=='$n' {print $0}' >>${patch_contact_dir}/${temp1}_patch_${j}.txt
					fi
					####
				done
			done
		
			####
			abs=$(awk '{sum += $4};END {print sum}' ${patch_abs_dir}/${temp1}_patch_${j}.txt)
			con1=$(awk '{sum += $9};END {print sum}' ${patch_contact_dir}/${temp1}_patch_${j}.txt)
			con=$(echo "scale=3;$con1/2" | bc)
			psaia=$(echo "$abs*$con" | bc)
			echo $j $abs $con $psaia >>${patch_psaia_dir}/${temp1}.txt
			#echo $j $con >>${patch_psaia_dir}/${temp1}_con.txt	
			####
		fi
		#echo $value
		if [ $value = 0 ];then
			echo ${patch_dir}/${temp}_patch_${j}
			rm ${patch_dir}/${temp}_patch_${j}.txt
		fi

	done
done

#calculate absolute accessibility area
#for i in $(ls ${patch_dir});do
#	temp=$(echo ${i%-*})
#	pdb=$(echo ${temp%_*})
#	chain=$(echo ${temp: -1})
#done


	
	


























