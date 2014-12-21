static struct mtd_partition mini2440_default_nand_part[]={
	{
		.name = "bootloader",/* /dev/mtdblock0 */
		.size = 0x00040000, /*  256kb */
		.offset = 0,
	},
	{
		.name = "booloader param" , /* /dev/mtdblock1 */
		.size = 0x00020000,	/* 128kb */
		.offset = 0x00040000,
	},
	{
 		.name = "Kernel",  /* /dev/mtdblock2 */
		.size = 0x00500000,	/* 5MB */
		.offset = 0x00060000,
	},
	{
		.name = "root", /* /dev/mtdblock3  */
		.size = 1024*1024*1024,
 		.offset = 0x00560000,
	},
	{
		.name = "Enti re Nand" , /* dev/mtdblock4 */
		.size = 1024*1024*1024,
 		.offset = 0,
	}
};

/* nand flash setting table for each nand flash */
static struct s3c2410_nand_set mini2440_nand_sets[] = {
 	{  
 	 	.name = "Nand",
		.nr_chips = 1,
		.nr_partitions = ARRAY_SIZE(mini2440_default_nand_part),
	 	.partitions = mini2440_default_nand_part,
	},
};

/* nand flash character accoding to the data sheet */
static struct s3c2410_platform_nand mini2440_nand_info={
	.tacls =  20, 
	.twrph0 = 60,
	.twrph1 = 20,
	.nr_sets = ARRAY_SIZE(mini2440_nand_sets),
	.sets = mini2440_nand_sets,
 	.ignore_unset_ecc = 1,
};
