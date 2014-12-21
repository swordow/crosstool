/* DM9000AEP 10/1000 ethernet controller */
@@@@#define MACH_MINI2440_DM9K_BASE S3C2410_CS4+0x300 @@@@
static struct resource mini2440_dm9k_resource[]={
	[0]={
		.start	= MACH_MINI2440_DM9K_BASE,
		.end	= MACH_MINI2440_DM9K_BASE+3,
		.flags  = IORESOURCE_MEM
	},
	[1]={
		.start = MACH_MINI2440_DM9K_BASE+4,
		.end	= MACH_MINI2440_DM9K_BASE+7,
		.flags	= IORESOURCE_MEM,
	},
	[2]={
		.start = IRQ_EINT7,
		.end = IRQ_EINT7,
		.flags = IORESOURCE_IRQ | IORESOURCE_IRQ_HIGHEDGE,
	}
};

static struct dm9000_plat_data mini2440_dm9k_pdata={
	.flags = (DM9000_PLATF_16BITONLY | DM9000_PLATF_NO_EEPROM),
};

static struct platform_device mini2440_device_eth={
	.name = "dm9000",
	.id = -1,
	.num_resources = ARRAY_SIZE(mini2440_dm9k_resource),
	.resource = mini2440_dm9k_resource,
	.dev = {
		.platform_data = &mini2440_dm9k_pdata,
	}
};


