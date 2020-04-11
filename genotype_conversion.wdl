task bgen_to_vcf {

	File bgen_file
	File sample_file
	String outfile = basename(bgen_file, ".bgen")
	Int? memory = 10
	Int? disk = 20

	command <<<
		head -2 ${sample_file} > plink_sample.sample && \
		tail -n +3 ${sample_file} | awk '{print 0,$2,$3,$4}' >> plink_sample.sample
	
		$PLINK2 \
			--bgen ${bgen_file} ref-first \
			--sample plink_sample.sample \
			--allow-extra-chr \
			--export vcf bgz vcf-dosage=GP \
			--out ${outfile}
	>>>

	runtime {
		docker: "quay.io/large-scale-gxe-methods/genotype-conversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_vcf = "${outfile}.vcf.gz"
	}
}

task bgen_to_vcf_2 {

	File bgen_file
	File? sample_file
	String? variant_range_filter = ""
	String outfile = basename(bgen_file, ".bgen")
	Int? memory = 10
	Int? disk = 20

	command {
		$QCTOOL \
			-g ${bgen_file} \
			${"-s " + sample_file} \
			-incl-range ${variant_range_filter} \
			-og ${outfile}.vcf.gz
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/genotype-conversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_vcf = "${outfile}.vcf.gz"
	}
}

task vcf_to_bgen {

	File vcf_file
	String? variant_range_filter = ""
	String outfile = basename(vcf_file, ".vcf.gz")
	Int? memory = 10
	Int? disk = 20

	command {
		$QCTOOL \
			-g ${vcf_file} \
			-incl-range ${variant_range_filter} \
			-og ${outfile}.bgen \
			-os ${outfile}.sample
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/genotype-conversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_bgen = "${outfile}.bgen"
		File out_sample = "${outfile}.sample"
	}
}

task vcf_to_minimac {

	File vcf_file
	#File? info_file
	String outfile = basename(vcf_file, ".vcf.gz")
	Int? memory = 10
	Int? disk = 20

	command {
		$DosageConvertor \
			--vcfDose ${vcf_file} \
			--type mach \
			--format 1 \
			--prefix ${outfile}
		gunzip < "${outfile}.mach.dose.gz" | tr '\t' ' ' > "${outfile}.mach.dose"
	}
			#${"--info " + info_file} \

	runtime {
		docker: "quay.io/large-scale-gxe-methods/genotype-conversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_minimac_gz = "${outfile}.mach.dose.gz"
		File out_minimac = "${outfile}.mach.dose"
		File out_info = "${outfile}.mach.info"
	}
}

task vcf_to_plink2 {

	File vcf_file
	String dosage_type
	String outfile = basename(vcf_file, ".vcf.gz")
	Int? memory = 10
	Int? disk = 20

	command {
		$PLINK2 \
			--vcf ${vcf_file} ${"dosage=" + dosage_type} \
			--make-pgen \
			--out ${outfile}
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/genotype-conversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_pgen = "${outfile}.pgen"
		File out_psam = "${outfile}.psam"
		File out_pvar = "${outfile}.pvar"
	}
}

task vcf_to_gen {

	File vcf_file
	String dosage_type
	String outfile = basename(vcf_file, ".vcf.gz")
	Int? memory = 10
	Int? disk = 20

	command {
		$PLINK2 \
			--vcf ${vcf_file} \
			--allow-extra-chr \
			--export oxford bgz \
			--out ${outfile}
	}
			#--vcf ${vcf_file} ${"dosage=" + dosage_type} \

	runtime {
		docker: "quay.io/large-scale-gxe-methods/genotype-conversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_gen = "${outfile}.gen.gz"
		File out_sample = "${outfile}.sample"
	}
}

task minimac_to_mmap {

	File dose_file
	File info_file
	String outfile = basename(dose_file, ".dose.gz")
	Int? memory = 10
	Int? disk = 20

	command {
		$MMAP \
			--mach_dose2mmap \
			--mach_info_filename ${info_file} \
			--mach_dose_filename ${dose_file} \
			--binary_output_filename ${outfile}_bin_SxM

		$MMAP \
			--transpose_binary_genotype_file \
			--binary_input_filename ${outfile}_bin_SxM \
			--binary_output_filename ${outfile}_bin
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/genotype-conversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_mmap = "${outfile}_bin"
	}
}

task bgen_to_plink2 {

	File bgen_file
	File? sample_file
	String outfile = basename(bgen_file, ".bgen")
	Int? memory = 10
	Int? disk = 20

	command {
		$PLINK2 \
			--bgen ${bgen_file} \
			--sample ${sample_file} \
			--make-pgen \
			--out ${outfile}
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/genotype-conversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_pgen = "${outfile}.pgen"
		File out_psam = "${outfile}.psam"
		File out_pvar = "${outfile}.pvar"
	}
}

task bgen_to_gen {

	File bgen_file
	File? sample_file
	String outfile = basename(bgen_file, ".bgen")
	Int? memory = 10
	Int? disk = 20

	command {
		$PLINK2 \
			--bgen ${bgen_file} \
			--sample ${sample_file} \
			--export oxford \
			--out ${outfile}
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/genotype-conversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_gen = "${outfile}.gen"
		File out_sample = "${outfile}.sample"
	}
}


workflow convert {

	String conversion
	Array[File] input_files
	Array[File]? sample_files
	Array[File]? info_files
	String? dosage_type = "GP"
	String? variant_range_filter
	String? memory
	String? disk

	if(conversion == "bgen2vcf") {

		Array[File] sample_files_nonoptional = select_first([sample_files, []])
		Array[Pair[File,File]] bgen_filesets = zip(input_files, sample_files_nonoptional)

		scatter (fileset in bgen_filesets) {
			call bgen_to_vcf {
				input:
					bgen_file = fileset.left, 
					sample_file = fileset.right,
					memory = memory,
					disk = disk
			}
		}

		output {
			Array[File]? converted_vcf_files = bgen_to_vcf.out_vcf
		}
	}

	if(conversion == "vcf2bgen") {
		scatter (input_file in input_files) {
			call vcf_to_bgen {
				input:
					vcf_file = input_file, 
					variant_range_filter = variant_range_filter,
					memory = memory,
					disk = disk
			}
		}

		output {
			Array[File]? converted_bgen_files = vcf_to_bgen.out_bgen
			Array[File]? converted_bgen_sample_files = vcf_to_bgen.out_sample
		}
	}

	if(conversion == "vcf2minimac") {
		scatter (input_file in input_files) {
			call vcf_to_minimac {
				input:
					vcf_file = input_file, 
					memory = memory,
					disk = disk
					#info_file = info_file
			}
		}

		output {
			Array[File]? converted_dose_files = vcf_to_minimac.out_minimac
			Array[File]? converted_info_files = vcf_to_minimac.out_info
		}
	}

	if(conversion == "vcf2plink2") {
		scatter (input_file in input_files) {
			call vcf_to_plink2 {
				input:
					vcf_file = input_file, 
					dosage_type = dosage_type,
					memory = memory,
					disk = disk
			}
		}

		output {
			Array[File]? converted_plink2_pgen = vcf_to_plink2.out_pgen
			Array[File]? converted_plink2_psam = vcf_to_plink2.out_psam
			Array[File]? converted_plink2_pvar = vcf_to_plink2.out_pvar
		}
	}

	if(conversion == "vcf2gen") {
		scatter (input_file in input_files) {
			call vcf_to_gen {
				input:
					vcf_file = input_file, 
					dosage_type = dosage_type,
					memory = memory,
					disk = disk
			}
		}

		output {
			Array[File]? converted_gen_files = vcf_to_gen.out_gen
			Array[File]? converted_gen_sample_files = vcf_to_gen.out_sample
		}
	}

	if(conversion == "minimac2mmap") {

		Array[File] info_files_nonoptional = select_first([info_files, []])
		Array[Pair[File,File]] minimac_filesets = zip(input_files, info_files_nonoptional)

		scatter (fileset in minimac_filesets) {
			call minimac_to_mmap {
				input:
					dose_file = fileset.left,
					info_file = fileset.right, 
					memory = memory,
					disk = disk
			}
		}

		output {
			Array[File]? converted_mmap_files = minimac_to_mmap.out_mmap
		}
	}

	#if(conversion == "bgen2plink2") {

	#	Array[File] sample_files_for_plink2_nonoptional = select_first([sample_files, []])
	#	Array[Pair[File,File]] bgen_filesets_for_plink2 = zip(input_files, sample_files_for_plink2_nonoptional)

	#	scatter (fileset in bgen_filesets_for_plink2) {
	#		call bgen_to_plink2 {
	#			input:
	#				bgen_file = fileset.left, 
	#				sample_file = fileset.right,
	#				memory = memory,
	#				disk = disk
	#		}
	#	}

	#	output {
	#		Array[File]? converted_plink2_pgen = bgen_to_plink2.out_pgen
	#		Array[File]? converted_plink2_psam = bgen_to_plink2.out_psam
	#		Array[File]? converted_plink2_pvar = bgen_to_plink2.out_pvar
	#	}
	#}

	#if(conversion == "bgen2gen") {

	#	Array[File] sample_files_for_gen_nonoptional = select_first([sample_files, []])
	#	Array[Pair[File,File]] bgen_filesets_for_gen = zip(input_files, sample_files_for_gen_nonoptional)

	#	scatter (fileset in bgen_filesets_for_gen) {
	#		call bgen_to_gen {
	#			input:
	#				bgen_file = fileset.left, 
	#				sample_file = fileset.right,
	#				memory = memory,
	#				disk = disk
	#		}
	#	}

	#	output {
	#		Array[File]? converted_gen_files = bgen_to_gen.out_gen
	#		Array[File]? converted_gen_sample_files = bgen_to_gen.out_sample
	#	}
	#}


	parameter_meta {
		conversion: "String representing the requested conversion. Current options include: bgen2vcf, vcf2bgen, vcf2minimac, vcf2plink2, vcf2gen, and minimac2mmap."
		input_files: "Array of genotype dosage files (currently, in VCF or .bgen format)."
		sample_files: "Array of .bgen sample files (optionally used in the .bgen to VCF conversion)."
		info_files: "Array of variant info files (used in the Minimac to MMAP conversion)." 
		dosage_type: "Type of allele dosage to read in from imputed VCF file (optional; options = GP/GP-force/HDS/DS, default GP)."
		variant_range_filter: "Optional string for variant filtering. Format: chr:start-stop (e.g. 2:100000-500000)."
		memory: "Requested memory (in GB)."
		disk: "Requested disk space (in GB)."
	}

	meta {
                author: "Kenny Westerman"
                email: "kewesterman@mgh.harvard.edu"
		decription: "Convert imputed genotype data file formats for use in downstream GxE testing, with Minimac4 VCF as the assumed base format. Currently implements VCF to .bgen, Minimac dose, or MMAP and .bgen to VCF, .gen (Oxford), and pgen/psam/pvar (PLINK2)."
	}
}
