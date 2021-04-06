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
result_dir="$main_directory/result"

mkdir result

for i in $(ls $pdb_dir);do
	pdb=$(echo ${i%.*})
	for j in $(cat ${chain_dir}/${pdb}_chains.txt);do
		sort -r -n -t ' ' -k 4 ${patch_psaia_dir}/${pdb}_${j}.txt -o ${patch_psaia_dir}/${pdb}_${j}_sort.txt
		#sed -n "1,1p" 1a8j_H_sort.txt | awk '{print $1}'
		patch1=$(sed -n "1,1p" ${patch_psaia_dir}/${pdb}_${j}_sort.txt | awk '{print $1}')
		patch2=$(sed -n "2,1p" ${patch_psaia_dir}/${pdb}_${j}_sort.txt | awk '{print $1}')
		patch3=$(sed -n "3,1p" ${patch_psaia_dir}/${pdb}_${j}_sort.txt | awk '{print $1}')
		#echo $patch1 $patch2
		echo "patch1 center amino acid: $patch1" >>${result_dir}/${pdb}_result.txt
		#echo $patch1 >>${result_dir}/${pdb}_result.txt
		awk '{print $2,$3,$4}' ${patch_dir}/${pdb}_${j}-by_patch_${patch1}.txt >>${result_dir}/${pdb}_result.txt
		echo "patch2 center amino acid: $patch2" >>${result_dir}/${pdb}_result.txt
		awk '{print $2,$3,$4}' ${patch_dir}/${pdb}_${j}-by_patch_${patch2}.txt >>${result_dir}/${pdb}_result.txt
		echo "patch3 center amino acid: $patch3" >>${result_dir}/${pdb}_result.txt
		awk '{print $2,$3,$4}' ${patch_dir}/${pdb}_${j}-by_patch_${patch3}.txt >>${result_dir}/${pdb}_result.txt
	done
done


