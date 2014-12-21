/*****/@@@@#if defined(CONFIG_ARCH_S3C2410)@@@@
	unsigned int oldval_bwscon = *(volatile unsigned int *)S3C2410_BWSCON;
	unsigned int oldval_bankcon4 = *(volatile unsigned int *)S3C2410_BANKCON4;
	*((volatile unsigned int *)S3C2410_BWSCON) = ( oldval_bwscon & ~(3<<16)) | S3C2410_BWSCON_DW4_16 | S3C2410_BWSCON_WS4 | S3C2410_BWSCON_ST4;
	*((volatile unsigned int *)S3C2410_BANKCON4) = 0x1f7c;
@@@@#endif@@@@
