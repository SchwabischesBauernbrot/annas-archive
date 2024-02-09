CREATE TABLE `mariapersist_downloads_hourly_by_ip` ( `ip` BINARY(16), `hour_since_epoch` BIGINT, `count` INT, PRIMARY KEY(ip, hour_since_epoch) ) ENGINE=InnoDB;

CREATE TABLE `mariapersist_downloads_hourly_by_md5` ( `md5` BINARY(16), `hour_since_epoch` BIGINT, `count` INT, PRIMARY KEY(md5, hour_since_epoch) ) ENGINE=InnoDB;

CREATE TABLE `mariapersist_downloads_total_by_md5` ( `md5` BINARY(16), `count` INT, PRIMARY KEY(md5) ) ENGINE=InnoDB;

CREATE TABLE mariapersist_downloads (
    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    `md5` BINARY(16) NOT NULL,
    `ip` BINARY(16) NOT NULL,
    PRIMARY KEY (`timestamp`, `md5`, `ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE `mariapersist_downloads_hourly` ( `hour_since_epoch` BIGINT, `count` INT, PRIMARY KEY(hour_since_epoch) ) ENGINE=InnoDB;

CREATE TABLE mariapersist_accounts (
    `account_id` CHAR(7) NOT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `email_verified` VARCHAR(250) NOT NULL,
    `display_name` VARCHAR(250) NOT NULL,
    `newsletter_unsubscribe` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`account_id`),
    UNIQUE INDEX (`email_verified`),
    UNIQUE INDEX (`display_name`),
    INDEX (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE mariapersist_account_logins (
    `account_id` CHAR(7) NOT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `ip` BINARY(16) NOT NULL,
    PRIMARY KEY (`account_id`, `created`, `ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

ALTER TABLE mariapersist_downloads ADD COLUMN `account_id` CHAR(7) NULL;
ALTER TABLE mariapersist_downloads ADD CONSTRAINT `mariapersist_downloads_account_id` FOREIGN KEY(`account_id`) REFERENCES `mariapersist_accounts` (`account_id`);
ALTER TABLE mariapersist_account_logins ADD CONSTRAINT `mariapersist_account_logins_account_id` FOREIGN KEY(`account_id`) REFERENCES `mariapersist_accounts` (`account_id`);
ALTER TABLE mariapersist_downloads ADD INDEX `account_id_timestamp` (`account_id`, `timestamp`);

CREATE TABLE mariapersist_copyright_claims (
    `copyright_claim_id` BIGINT NOT NULL AUTO_INCREMENT,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `ip` BINARY(16) NOT NULL,
    `json` JSON NOT NULL,
    PRIMARY KEY (`copyright_claim_id`),
    INDEX (`created`),
    INDEX (`ip`,`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE mariapersist_md5_report (
    `md5_report_id` BIGINT NOT NULL AUTO_INCREMENT,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `md5` BINARY(16) NOT NULL,
    `account_id` CHAR(7) NOT NULL,
    `type` CHAR(10) NOT NULL,
    `better_md5` BINARY(16) NULL,
    PRIMARY KEY (`md5_report_id`),
    INDEX (`created`),
    INDEX (`account_id`,`created`),
    INDEX (`md5`,`created`),
    INDEX (`better_md5`,`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
ALTER TABLE mariapersist_md5_report ADD CONSTRAINT `mariapersist_md5_report_account_id` FOREIGN KEY(`account_id`) REFERENCES `mariapersist_accounts` (`account_id`);

ALTER TABLE mariapersist_accounts DROP INDEX display_name;

CREATE TABLE mariapersist_comments (
    `comment_id` BIGINT NOT NULL AUTO_INCREMENT,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `account_id` CHAR(7) NOT NULL,
    `resource` VARCHAR(250) NOT NULL,
    `content` TEXT NOT NULL,
    PRIMARY KEY (`comment_id`),
    INDEX (`created`),
    INDEX (`account_id`,`created`),
    INDEX (`resource`,`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
ALTER TABLE mariapersist_comments ADD CONSTRAINT `mariapersist_comments_account_id` FOREIGN KEY(`account_id`) REFERENCES `mariapersist_accounts` (`account_id`);

CREATE TABLE mariapersist_reactions (
    `reaction_id` BIGINT NOT NULL AUTO_INCREMENT,
    `account_id` CHAR(7) NOT NULL,
    `resource` VARCHAR(250) NOT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `type` TINYINT(1) NOT NULL, # 0=unset, 1=abuse, 2=thumbsup, 3=thumbsdown
    PRIMARY KEY (`reaction_id`),
    UNIQUE INDEX (`account_id`,`resource`),
    INDEX (`updated`),
    INDEX (`account_id`,`updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
ALTER TABLE mariapersist_reactions ADD CONSTRAINT `mariapersist_reactions_account_id` FOREIGN KEY(`account_id`) REFERENCES `mariapersist_accounts` (`account_id`);

CREATE TABLE mariapersist_lists (
    `list_id` CHAR(7) NOT NULL,
    `account_id` CHAR(7) NOT NULL,
    `name` VARCHAR(250) NOT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`list_id`),
    INDEX (`updated`),
    INDEX (`account_id`,`updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
ALTER TABLE mariapersist_lists ADD CONSTRAINT `mariapersist_lists_account_id` FOREIGN KEY(`account_id`) REFERENCES `mariapersist_accounts` (`account_id`);

CREATE TABLE mariapersist_list_entries (
    `list_entry_id` BIGINT NOT NULL AUTO_INCREMENT,
    `account_id` CHAR(7) NOT NULL,
    `list_id` CHAR(7) NOT NULL,
    `resource` VARCHAR(250) NOT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`list_entry_id`),
    UNIQUE INDEX (`resource`,`list_id`),
    INDEX (`updated`),
    INDEX (`list_id`,`updated`),
    INDEX (`account_id`,`updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
ALTER TABLE mariapersist_list_entries ADD CONSTRAINT `mariapersist_list_entries_account_id` FOREIGN KEY(`account_id`) REFERENCES `mariapersist_accounts` (`account_id`);
ALTER TABLE mariapersist_list_entries ADD CONSTRAINT `mariapersist_list_entries_list_id` FOREIGN KEY(`list_id`) REFERENCES `mariapersist_lists` (`list_id`);

CREATE TABLE mariapersist_donations (
    `donation_id` CHAR(22) NOT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `account_id` CHAR(7) NOT NULL,
    `cost_cents_usd` INT NOT NULL,
    `cost_cents_native_currency` INT NOT NULL,
    `native_currency_code` CHAR(10) NOT NULL,
    `processing_status` TINYINT NOT NULL, # 0=unpaid, 1=paid, 2=cancelled, 3=expired, 4=manualconfirm, 5=manualinvalid
    `donation_type` SMALLINT NOT NULL, # 0=manual, 1=automated
    `ip` BINARY(16) NOT NULL,
    `json` JSON NOT NULL,
    PRIMARY KEY (`donation_id`),
    INDEX (`created`),
    INDEX (`account_id`, `processing_status`, `created`),
    INDEX (`donation_type`, `created`),
    INDEX (`processing_status`, `created`),
    INDEX (`cost_cents_usd`, `created`),
    INDEX (`cost_cents_native_currency`, `created`),
    INDEX (`native_currency_code`, `created`),
    INDEX (`ip`, `created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
ALTER TABLE mariapersist_donations ADD COLUMN `paid_timestamp` TIMESTAMP NULL;

ALTER TABLE mariapersist_accounts ADD COLUMN `membership_tier` CHAR(7) NOT NULL DEFAULT 0;
ALTER TABLE mariapersist_accounts ADD COLUMN `membership_expiration` TIMESTAMP NULL;

ALTER TABLE mariapersist_accounts MODIFY `email_verified` VARCHAR(250) NULL;

CREATE TABLE mariapersist_fast_download_access (
    `account_id` CHAR(7) NOT NULL,
    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    `md5` BINARY(16) NOT NULL,
    `ip` BINARY(16) NOT NULL,
    PRIMARY KEY (`account_id`, `timestamp`, `md5`, `ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


CREATE TABLE mariapersist_small_files (
    `file_path` VARCHAR(256) NOT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    `metadata` JSON NOT NULL DEFAULT "{}",
    `data` LONGBLOB NOT NULL,
    PRIMARY KEY (`file_path`),
    INDEX (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin PAGE_COMPRESSED=1;
ALTER TABLE mariapersist_small_files ADD COLUMN `data_size` BIGINT GENERATED ALWAYS AS (JSON_EXTRACT(metadata, "$.data_size")) PERSISTENT;

INSERT INTO `mariapersist_small_files` (`file_path`, `created`, `metadata`, `data`) VALUES
('torrents/managed_by_aa/libgenli_comics/aa_lgli_comics_2022_08_files.sql.gz.torrent','2023-07-17 22:52:47','{"seeding_at": "2024-01-04T05:56:41Z","btih":"c9130dbd834dd568ac9d8c6e258b595776c26c31","torrent_size":9706,"num_files":1,"data_size":91717561,"embargo":true}',0x64383A616E6E6F756E636534323A7564703A2F2F747261636B65722E6F70656E747261636B722E6F72673A313333372F616E6E6F756E636531333A616E6E6F756E63652D6C6973746C6C34323A7564703A2F2F747261636B65722E6F70656E747261636B722E6F72673A313333372F616E6E6F756E6365656C33313A7564703A2F2F392E72617262672E636F6D3A323831302F616E6E6F756E6365656C34363A7564703A2F2F747261636B65722E6F70656E626974746F7272656E742E636F6D3A363936392F616E6E6F756E6365656C34353A687474703A2F2F747261636B65722E6F70656E626974746F7272656E742E636F6D3A38302F616E6E6F756E6365656C33323A687474703A2F2F39352E3130372E34382E3131353A38302F616E6E6F756E6365656C34303A687474703A2F2F6F70656E2E6163676E78747261636B65722E636F6D3A38302F616E6E6F756E6365656C33303A687474703A2F2F742E6163672E7269703A363639392F616E6E6F756E6365656C33363A687474703A2F2F742E6E796161747261636B65722E636F6D3A38302F616E6E6F756E6365656C33373A687474703A2F2F747261636B65722E627434672E636F6D3A323039352F616E6E6F756E6365656C33373A687474703A2F2F747261636B65722E66696C65732E666D3A363936392F616E6E6F756E6365656C34333A687474703A2F2F747261636B65722E6F70656E747261636B722E6F72673A313333372F616E6E6F756E6365656C33363A687474703A2F2F76707330322E6E65742E6F72656C2E72753A38302F616E6E6F756E6365656C33363A68747470733A2F2F313333372E61626376672E696E666F3A3434332F616E6E6F756E6365656C34323A68747470733A2F2F6F70656E747261636B65722E6932702E726F636B733A3434332F616E6E6F756E6365656C33393A68747470733A2F2F747261636B65722E6E616E6F68612E6F72673A3434332F616E6E6F756E6365656C34303A68747470733A2F2F747261636B65722E736C6F70707974612E636F3A3434332F616E6E6F756E6365656C33323A7564703A2F2F3230382E38332E32302E32303A363936392F616E6E6F756E6365656C33333A7564703A2F2F33372E3233352E3137342E34363A323731302F616E6E6F756E6365656C33333A7564703A2F2F37352E3132372E31342E3232343A323731302F616E6E6F756E6365656C33373A7564703A2F2F65786F6475732E646573796E632E636F6D3A363936392F616E6E6F756E6365656C33323A7564703A2F2F6578706C6F6469652E6F72673A363936392F616E6E6F756E6365656C33343A7564703A2F2F66652E6465616C636C75622E64653A363936392F616E6E6F756E6365656C33393A7564703A2F2F697076342E747261636B65722E68617272792E6C753A38302F616E6E6F756E6365656C33333A7564703A2F2F6D6F766965732E7A73772E63613A363936392F616E6E6F756E6365656C33363A7564703A2F2F6F70656E2E64656D6F6E69692E636F6D3A313333372F616E6E6F756E6365656C33333A7564703A2F2F6F70656E2E737465616C74682E73693A38302F616E6E6F756E6365656C34313A7564703A2F2F6F70656E747261636B65722E6932702E726F636B733A363936392F616E6E6F756E6365656C33353A7564703A2F2F7034702E6172656E6162672E636F6D3A313333372F616E6E6F756E6365656C34363A7564703A2F2F7075626C69632E747261636B65722E7672617068696D2E636F6D3A363936392F616E6E6F756E6365656C34323A7564703A2F2F7265747261636B65722E6C616E74612D6E65742E72753A323731302F616E6E6F756E6365656C33333A7564703A2F2F747261636B65722E30782E74663A363936392F616E6E6F756E6365656C33363A7564703A2F2F747261636B65722E646C65722E6F72673A363936392F616E6E6F756E6365656C34303A7564703A2F2F747261636B65722E66696C656D61696C2E636F6D3A363936392F616E6E6F756E6365656C33383A7564703A2F2F747261636B65722E6D6F656B696E672E6D653A363936392F616E6E6F756E6365656C33333A7564703A2F2F747261636B65722E706F6D662E73653A38302F616E6E6F756E6365656C34323A7564703A2F2F747261636B65722E7377617465616D2E6F72672E756B3A323731302F616E6E6F756E6365656C34303A7564703A2F2F747261636B65722E74696E792D7670732E636F6D3A363936392F616E6E6F756E6365656C34313A7564703A2F2F747261636B65722E746F7272656E742E65752E6F72673A3435312F616E6E6F756E6365656C34323A7564703A2F2F747261636B65722E6F70656E747261636B722E6F72673A313333372F616E6E6F756E6365656C33373A68747470733A2F2F747261636B6572322E637469782E636E3A3434332F616E6E6F756E6365656C33363A68747470733A2F2F747261636B6572312E3532302E6A703A3434332F616E6E6F756E6365656C34313A7564703A2F2F6F70656E747261636B65722E6932702E726F636B733A363936392F616E6E6F756E6365656C34363A7564703A2F2F747261636B65722E6F70656E626974746F7272656E742E636F6D3A363936392F616E6E6F756E6365656C34353A687474703A2F2F747261636B65722E6F70656E626974746F7272656E742E636F6D3A38302F616E6E6F756E6365656C33363A7564703A2F2F6F70656E2E64656D6F6E69692E636F6D3A313333372F616E6E6F756E6365656C33333A7564703A2F2F6F70656E2E737465616C74682E73693A38302F616E6E6F756E6365656C33373A7564703A2F2F65786F6475732E646573796E632E636F6D3A363936392F616E6E6F756E6365656C34313A7564703A2F2F747261636B65722E746F7272656E742E65752E6F72673A3435312F616E6E6F756E6365656C33383A7564703A2F2F747261636B65722E6D6F656B696E672E6D653A363936392F616E6E6F756E6365656C34303A7564703A2F2F747261636B65722E6269747365617263682E746F3A313333372F616E6E6F756E6365656C33323A7564703A2F2F6578706C6F6469652E6F72673A363936392F616E6E6F756E6365656C33323A687474703A2F2F62742E656E64706F742E636F6D3A38302F616E6E6F756E6365656C34303A7564703A2F2F747261636B65722E74696E792D7670732E636F6D3A363936392F616E6E6F756E6365656C34343A68747470733A2F2F747261636B65722E74616D657273756E696F6E2E6F72673A3434332F616E6E6F756E6365656C34313A7564703A2F2F75706C6F6164732E67616D65636F6173742E6E65743A363936392F616E6E6F756E6365656C33353A7564703A2F2F747261636B6572322E646C65722E6F72673A38302F616E6E6F756E6365656C34313A7564703A2F2F747261636B6572312E62742E6D6F61636B2E636F2E6B723A38302F616E6E6F756E6365656C33383A7564703A2F2F747261636B65722E7468656F6B732E6E65743A363936392F616E6E6F756E6365656531303A6372656174656420627932333A707933637265617465746F7272656E742076312E312E30343A696E666F64363A6C656E67746869393137313735363165343A6E616D6533353A61615F6C676C695F636F6D6963735F323032325F30385F66696C65732E73716C2E677A31323A7069656365206C656E6774686932363231343465363A706965636573373030303A254D6084E18A4B54853DF5589AC7B582DF99A7BE3F426104A20B704BBC8F5B73F0EF3FD6F2CC2F11550933197F576F185FCF9B6913038702E06A78C9F5EE6E8519470D51CF2933438B1B43CD79975EE75400A53EDEFA05DADAD87074DFA24F640CAA78C9E413057EF29902E20395B1B4F131049F1FCCF45943B4820362ED1CCD90D53E879304968686BF1135DF6AA6348D48392AB95DAF800C52D5506F67F919D001623EAA7AE1FFEC06BE373C191D7365514BF204497856F567A54131680239E95C8BBE317E5623F14C8A37B836FAF511DECE8468D06319F6C891F2743840A9548B6ABB96722B23B446728721AE10A7FD2CC47FEEE41D8908E6BC7EC1668AB3F25C8A3F6977BC4D957069DDE50C3BD308D27658E764656B3E119BCE0D8BB1C422095444D7B154BE03F91A39E6418EF708A07CA4099C25A16326991439A5D8F9E37C6C408A42FAADB117CB1FBBC54E8D232E51BAD105075EDD79B1565615C0557932546122D1F86744E598747307A23616CC7AEABF3A4CCA7270D779F7971B12D91C63819BB4EC48D0C9C14678DE49C5FBC04A8C24013A79807A32D3D1732FC26368FAAB1F88DDB54E026A12178EC5A2056D69D4935970D6F7D8BA4C5A22FA02A7A6D4739C26951E93A9134A988D394B77331FF8B98EFBF969073AAA36398573964DA8FCFE86ED44BBFEDADAE69E96A582B46D62C26D6997970171CF8CA159AE723F9B97C8B39AAFE478D611F37393C738E18E650B7C65AB81E529258BA11419F1A5744412948461F6455655775CE21459FF6385DE819320BA45BF270E0AEF0F0AEF9BCBC04C945E4B9814FE13E8D68769C4C9881C9D1077A128B41575CB3AB1F5654E7011A3C138B2B72148471312BE263BD1022536584AFA69915D8128D5AC36AC4D104CC6F357F68DB0EAFEDB56BDF32175347831901479728C20A1263A7088FCD84DE82B8A133FE7752BF5101F0A1B15EEFAA82FDB94431885208B1A15625C742ED751A056D6AFFF6DA2D35E78D7F9D573E32D82A542686045DC015E447D51962DA3FC7A5912CB1B66A69308063BE2EA064C825505BD43C115003DBC5465B01ECB572879C0751C97570C71237D771C62E4D2BD8137DFB24261D008BBDD0856BCD9996E5B9E20014A2F74F9F0E15E35B43ACDF80BAEC9B75F5EACD32AEE563AB4AB479936A1402AC96A2198344D9827316C7330A4484981D221515598AB8FDAA690273877833989F930D325C51272E4A5092814CE1E56594913152B50675266EB2A2C988BB1EA2E7C06D12BF6519F1C8090B03BF408548C2D55EA74A5C025CC13638E623503A0D0398AB4473FC41D0F2336CEFB238F17EF8760FFDF0F068554EBD29C40BF120F2B76F325737B32DE083A9287865BBD64CBA44E30873496C4E8DFA1194BB0BD1A8B8CF9FE11D3F58982C4AA895FBDFCD64DCFE260CBCEBF1BF072DBF1DC4C8F5A7201AC04329053F8D5666C3966FCAB05659E7AD7C9A496806F1C49A7E20BC7D82EF935BB4BC2EC7C88157E65651BB6D972BA84C3F1168557E3FD5FD3B86A2B4B025C5225B8C17EF7A53C1628AD621855AB88B814E45C34B2E947BC9422D6BFF4EF2917C7BC8408427685A7E12FB30BC5F1BE592A58F13CDE085AC9470EC95B38B36EA496960099311401D08D0D0AC84D1ED639EA935071AE0238CFEDFB51C2B604586416ACB6CEF921E8C0091AAB551F365520E7FAB0A8AA156130136EBE8A9636DF9A6754030B06E6DAB0073C5D115317DBE2663736FF6DC2CB47F1D10494E709BD61017E1B2C1C7A4511C8D7A77700094B994B8380196C4DD78C81ADAAD2D91766D1583B8D10A4BADA72A6341E2B92E095A210506B5206AA3D6299EAAF4375582E0E37CE2DB139DC414D0C5AA3D47DD171FDC1291A76EEAAAC17EB4982293762CE4735AEB24BA803CE85EC5804F3DB457403A45477E4E8E3FC7533C4BD7FA612D2FFA47635CCB55044C2F5615EAAF166AAF82D13378FFC885411C2C6DEE47C93E75961794DDB77A53DC10BD493E836DB9319CF11E0D3E38AFDC9D4054DE1D3E3B36A3542A497FF27EF89578B555245C33C498701AA6D1D50B836BE27C18B4DD9D33816F4AE1849C680B0D32B9B12EF2F728226B1A39E111C5C27154C31664C226594FC9D1163087301186205FFE0680951EF13D3E95B235C97E349D6C49E4FA5CEA4DF4D0BFAD95DC136A9D66623EA0730DA41FB92DC32D4177D2AD8C755E12C30E0D04D341606D9CE570A06F5DD8235FC3163603FBDD73F8DD64430AEF467C1A82775AE2E07D8466BD1C191E89A6EC52CDF151C0E1D2D985490810E6D6CA35081F8A155B8C270D813087745894AA40C508F19DDB7219E8855D836B850325FB4ED48323CFB88594AC729F976B442D855F8FDC629BD4DE971703F3B5E5B8D0CA95F46A8EFDB9BD03C8D05A6DEF950456FADC5B5E1BE9901036A871A3910D3D1EAB336C47C26F96371FA687BB648CE469300D56063605D1510FDC1929388EC93E4AD2542EAB66C67063E32243F2F8DD168925FD45B990A0E7BFD734B17309C69E6FA12F0C93D2F2FBA80BE485499F1D3477568D8D03FE103544EB004479693FD354AA41BF3B859F036171E8BC32711103CDD6B4F57FE925B239AEA2715EEFD0719F54881684C9F21BA7753BD2750C30CEF12F40A519241A8CC055A0CC51E3A9270929B7526053D96059F1A2C7BE372320B167649A37283FAA1D22872904425FBD6EAFDD120429BD855C29B82ACDCD25B42DD83D9277DA2ECCC4F6812EDEEA91A2FD17B9E718D7EF9F7B517EE5B12198611995CA628F7B82F63A1C5689BB92FAB6EB8748352B2E43F112CA38318935F3A15DDD217A9CAD1DD3BBFF05C235E08880DC6C4DEEEC2760E71D0810FDA9E1D9983415E30C7B7C15F49FABC71FC5A9A248B12BEDA6A2929AF1BE97EF19F343CCD6DB2B202E42242590F5F72C7BD2CB6DEFA1DB1B91199CC6685371267F7F24247E305AC92FEA60094DD630ABE6C54C5CCCE803730DAE6B39E6BEC09BCDB45232363D69310503CFCF86AE83A7229B6423115C69E3575E89820876CE592466BBE9BB196FDC5021664E1B3AB3207B4CE7AE3DEAF7156086E50D06E9AF73FD26E4D88E2F73B81F69AAFDC90BC91FD9DA70624E13BFFD6CCF4E4BEFFB260D34A6F0E37E46E33C3CF68345D15BA12AD04593E503FFF39AFC7E3E1AA6683058E71FA800B8839009F53B0A877EFED10B1CC28FA14D1F402C9BA47BB369BBA9EC3EE50EC937800473983E98088480A97B9965448435593CDFFC2D508E2352D82FB944EBFF13E409556B3D3C54BEE2A0B8FB221378EBBFAAE905DD4221DFBBAC3570D3CDE7B55CA35823F2B90245B30ADEBE5D557DF4B48FF0FB8994F796453024FD55EFB9358A11AD674ED69E3C72F42B899D97E1825E0A2709B590A6BADB60D5D86FA46E1F0CF0209788042486CB66D390188A7B7F004083BA54C349A6B938A88476A2162EDA6421121FC050A96016BF0C4659C21B1D10BB17A101287593739CF734BABF39C5C8807FE3D9299AF0032DA37CD1F8CAD7440D471F00BA306E001BAC3AA7DB7FA246C493DC74A92881D5C488E8AE06B7AF6282B8585886DAB6F0E610E4EF3186698EE70369230ABD8D64F7A159FD90D36753F4E8DCFAE8298ACE3A6CB32E41CE6EFE241F6B023C2D2DACF8E145E91BD9A28052A8ED6BC521A9A490B48AEED07F07F8057C3E0575CE7095B11B34E77A53FB6CF4460B3F618ABCB24FA0D1260B7665DF6981A6F4216E3E383C5F52D00BC6A031A2D88618BF0942CF2CA4AF05385716D0F41540AA1359963F132F2216DB2556E17FD4886A507C8314677CE76788FD076C1782D0509CC74269DCCD836BFE23F8B2F76BB9E2B29B7394B8752211360B9A9D843F424EECC9284BE592CE97E0F7753C632786F86A9121331BA3976DC854253302071B13807A8FFA2F34C54EE3C076F0876C11E15DF7FA95760D03F913984F4B72A18341B9A2DF49366B5DFC86A46CECA85AE22521B9EAFCFBDD714235DCECE4EC807BF036177843944CFB587E007C4100BF376681261CFD3437E5397D6DAC5E1653EEED73545E2C6DB25D06703599B6758454B0F000092F703E416D0CCEA4D880A4C031B9A51C0406BCE315DC2DF6539F47BBA230E4A56B4ED87E4887E0E23AD44515AD41DCF36B476D5AA1134B12F0158CF2C6216BF78946843DBFD8A66B0B0E7439CA7470315259E4CD9A0D7A2589CE2D6EE45D9ED758544A527E511C957A45823CE5737BC5D6C5258DE3A45DA16243D758F750DF2782A4F2001AB1BA04D040AC8CE80EA15360B7FE93BDFDAADC2E378F8D838DE2F8481FEEBACD40CCF124A1F4DDCAFA713FF7596EE7EA524D48EDF5445D66063442198AD4A261F4A84D1978EF0D3F7F8E4B8C873D48FA0B333FAF00B4BA2ADE09080D9F6042CC0293B974BD0B6DC020E5DDB9355EDA7ACC25EEF0AB8769A7A88277223E13A98426ECF71B42D9BEC87BE825FA715D24D87D50AA844F9AFECB9D1F6A120F9EEE5B58A4D7ED1B50CA0AEA876D25FC1099DE3A93665AD192C2659FE1C34A43934ADED0BF4B2A7A723793C5AACC3813124F83BDC2AB1A6B9E58D7FBBA66C4B7FEF4396978A081DE1900EFB98253033BCB4A6AFF8D35521CE3289316FBCEBC050517BC63F351E2492689E29E43D2929B4423482D04B6B8C8FCCD17FA3F4F182EC25D3D392ADA8672652D6126C43D93C0DCECBF8DC1E752EAB60B1A58C21FC44D277BB14593D9175DFD7C54ACE96CB6E1E6300E86809A0C5FF431FFF8F1D6858215E7BA2EBEDE6CF30468501FEAAA4D80DBCA577A7E5134F2D1997CF97C6F35673FEC8E3D242AC761D94B4ABFDED58EF5ECEF0D50AB83612B25E500B488EE8CA4F38DF2560C13514D64BC0E96788CC6D0396346199DF590D78056449D675A7C851957D76782CFBF092F23E6693AA45855A472117D667872CB801A857119F12E99E4B0C2B9FDBE66F0D5C68E842A624445DFA9A39E2826A1B796D57054EEE48AF2E3553462386A0BCF83D6CE2F59D4F844DE059CDAE366A3BF2C316DE2D27B46008142004713EA169CF29B93C34CDCDC0DF46E05D1E050B976E4CF333E688F1C0DDD307A46B77574D6B14192DEC50335AFEC7587E1BD4D16CC4D4392F3CE5040784779CE23CE30F5021D996C97643D24E44F688B5E5CD363F9ACDE61145097A50235EAD6977EE212C2E43C8FDA87C8567CF94048AE03CE287C700761E71AB72F9E55F1181593C828B038C4931E4B1AA8D297B5397992D383FF579BF301112945BC770B7934DD3B8C896C2907D3F488F26446657EB2EC5C296FF96713D7333164CD5A3474645C1767FD3F61D5CB836B98D04145423122323EFFD3FE50ADB5FB6DEC2FBF62C48ECE1FE9E89AF2927771C5A001E571C2CEBDC9E66ABCB1ADC9CD5A1E0D782EA4FF88CAB2ED40D9CD6BBB7998F43951F5402B5201A673CE9FAE270E21B4C0F0790FA5E3CC7B98449B97649A4EF1FC67556DFFF1D970634C251569EC93484FC3D9B0BC6B75AF810EA4BF25530F95F6EB3732DE1E52464A5B30667A8FBC41FBAEC640F595979F1217A2B1ABCE52D2ECDE077333262B7BB8263B8AA6DB2F67C80D3280A1011B642D7607A17EE9001E8F66ABDACC417919C1AC9A2131C41140E1AD2C3AEC4F926CCB520169886F9A778F168481C0AB74B24A3F9D753E291202C3E872B1603DDF5B4EA995A6013BC3956B1F35738B2394896BEBC09CB4B3ACCFF501B4E4EBA85E514B8E6DEBC81ECB8F709D9305526EF36EC38F5902FDD828030B3A119BFCACF72CAA39CFB2F129A8CF33279242FE36DFAB380AE24CB09600AFA075D8E6D06919D20C1DAC2605A582DBB6C730439BE845583F0B9ABDE8D879ABE2479CD4E3EA712CDF588FE44F5E997D17DFF32F3462A07B0CD2291DCB0F4BEF591E62868E6C853612A97F95F996296A1FC34240257C17889219244DB810DC563577E9203048393971F6A204EB13459E21451DFB27BA478BA16F7A570D15C5AAC09171D043986191E8E7BF92F184FDE1779F3D650334E24E4F62B0A034A654FB0C825DF0D662C83FE27237A9D2687FE26A055EBD34EB255176EF5214F57581DDEBB1A56342ADDE419E19C79FCE1A49077151FB4EBF6E20BBDFECFE68C09F47D6205EF5CB97F52204A7DCBAF00BF79F25F8BF0D859C02C08F0752C23AE05704F2A2FDCC851A7A1B9684BF6B0D24060893D439A6B62E72795D4C768F82F92A3921F699DC8C2112803B106EBDB62AB5A72B2212D597D08D52266DFBC1BEBF5F260EB39C0BE2273B917D005F5A310B8814831929498B51F22A1CE0E8F54B2154C080D49EF2A96CB1A30F0DA228637DC7C59E5A290226F6B61D223453B3C55489DD4278F01E5E4D9662DADEEE9D7F6603F62B26254036DC5CE3257F047D982C46C4DB2BAE04658B24CA88D764F3B4CF108B1CD1623B9C326E2400CC34183E95FF3EBF20C2DFB3919B291C645319984CBF6D5E25554FFA4BD32FAD967D3DB0A4E35FA3FF70649E639E36CEE8BC4FAD194AFB5FD95906B6F83489887A5DBE524C8B030D886FA6563FE25F9158E8F879C2D57AA9E300933FC7EBF2C05A030936E4BC254F2FF71482B32E04974672D18E37912FDC0D15BA65A3D22C71CEF8FC5A51065928ACCECB97706D2D57AE6C764C48778B0E3230C1A3DAD1F8D3B0880A99842999E6D7ABADCBAF589343087249DF1FE39FC43616234B4F8B62172D6244BFB6D50B8A26809588BB0A663665AE59796CFA7EEE069A46ED8A0946099C74BBD8F2067624489D45657E9DE9BBD42B10919788A0034A4C4E243C4DE73763FD920F3079645CED72DA70A3C0FB9CECE0EF14E582514D327163531EF6F47241BDE2B540D60D698280DE7A6634F6205955956E16E8339CFBB031F511575F58B46F3541865CADE102B8233A1FB6D21F7D71F8C6A3CF7A7DAF7415D86857B179146346FE9FD2363B80891BC311BB7AF195890DD9F5622284DBA54B7B396A25E088C88F671BDA47DFABF635868F9FCF9C7D989B129FDDAECD207229009C685041283F75CCC853E4B0EC6F5AC5DAC10380F6991C959588481973DDF6905C2B567954701E9CB47B9CAB198DA7191188A59BDBE384D88C34D2DD89AFDF9862E05AED8C5D070CF954338BB273CDBF9AB60715FE5439226FDFE404E27A67A557C6254EB36876F9AFA6B521A3AC5E482EED9A27BB92C594CA6986F1EF0C33F740CA0EAC142CDE2166612F07813A2786AA32D0693D8C97919290B8D42CAFE3B6C6277E59830AA4241C4B8A54448E9D6AA4E716381D534FC9657DFE2641E9FA5B234A073471D96AC4C2082938CA89E249FBC526DA761824C48796F23D75420F0BB7A97BD2EEA4558DED800029408449EE10F5CB85F3294240DE44273C000D11F14D200831EF6578BD846DFA07A8BA7001D6E300CA205C779B2EC696166FFE8D6DD952579501ED9EBB4ABD4921311867A331C2B0F48177F29E4FC074221EB1DBCE6B0BB561923513A73E25D2AE16C09B63EB7D595DB5916D8B3D9CF056543DFE06694AA8DAD2369A5048BF24D8A8FC283B05CD81F6D6657BA8072F570CD9EA407B5FDB113BEEBFE0EAFA609BC1CE50DC27C4DEA6702FC62151BEE453AD3A63491ED35D81C5407F30E42EAC10BDFC1412E145E27E29DDB375E60FE0EAFCF0CF13373E4890A47BD13FE4C628FFBA53C3C609E409A1B2EF60B0E3C96200653877FDCB3E629BDB94DF417CD24F69C9B8B4806298AAEF0C69AD8DFFE53EB665DCB16FDFE8EF2E45CB12375E2C0F7F34AF049BA47AA22004C7CF61A1EF8735CF31A2429548DA3144F0CFF7A5627FF3D7763D225CBA43788711EBE820B6F8B3EDC8B627BAAC455C98F33A6204BE57ECA96952232CFE78B9674338CC5BCAB1CF3C36FD3873DA3C61E08E7946601F9DAF7EC3B9160B4E7E445E60739F32DA9D3B1D80F34CA9B683115C7D1260F3DFCFCEBCC3E9AE7DA087CCA734C277D91316A26F0741903F031CA7389203B3DF83ABD5A7D64AFE8B4CC5F999F966005B4A9FA6DC564ABF5E398FE2B029B89BC988E6174664F313BD7A1F6DEEA7E6FE1EAAFF5CCF25923198873613DD0A634DE56DF1797906B859BA99C7FE816127F48FBE7754CE0692F6E47E40975733AA37CA1694FF9D82EE0D96534153F613E42E7FF4964973D7A3D352B30C5277AFE0E3DA1F070EAD4D02722D29628F7B73D004D2DF760EE6EDB23C9C5FF9F02DC0DE0ED7ECA0489F1B2BB9F38131B78995D88B11B0F3B978A256229FF1FED37A6D663D930BF3F9368894360B81D3494B9104D53F9AA00889AF57723520C0E3D08EC30015370171BB6AAC35311969347627A6BD98DF920D817F6C33536A4159CFCD18AC62BE8662FDF27C22E2C750EF39500B3A9F1AC2948A4D8FD86E4CB374D2757E7BD4BFB6AD25556661267984474A8FAEF6D38FD9CD9CBD6459B39110C53C3826F448B86ED4AB410134EBE3C1BF1DFD227BFB4BBFDF907F389052C1D80C7A5D33CDE5643C6273FE7BF87B8D4A574760C4293548851A42BBEB132EE4F5D7CA78096DC5867225932F3BF097299B50342BCD28087339D5EDDE32D99ABCD499960F94307BE087D0AD5457FFFF404CFE7786AAA264908BEF3FEF487254097AF9CF5530D155F52AF2F5764B8F7B855E6101CCBE40D1D561243F37A8DE5A9AA8F3AD0D7D813C7B42467A1A75D1D9B3275ECEB548EB73BD0A6DB9C71ABD2768611F533748D450EFAE622E338CD92CC5FAFEB3D6C5482DA88EEEE21D28DBCA7FD92528CA6016CEB500F2CE4D314278C65030BC86064BBE20EF1CF404768C70CA3BB48BFC01CE78AA9D43658233488BDAD48B3A9093A323735E45911339AA5175A19DC3F734E3DA290A24E64D7969EFF9A194018C9498700D4423D3232C5613FD175108E6294EB0CF5F72ABAB8BB6AFFBCB9D639BAC0E10F257DD9299B977C2D6D596FB3BCB37B8FEEB525729D13E770FDAC66677F58AA7CE9C5C4B85FB009792036A30B1E19ABB7B8FEC1DABEADA7852AA3930CD76226FB686D4F654994D116E3A4D26D3B65B43668894AB8EAA06D46DD3775C322B37049B46AB4EB5E30856755020313C9FE0EA79873B087CA7C009DF706889E8CE657195BB78238FCE5094A11E3CEA8D5CADE7EE76F1F033B26F17609B9590EF261DBC686DAF79133A352B93A0D7F099007868599FF49AA48BF84135EBC64781D28F3E433097BA495FF3FB5ED7553D84DE502B08AD939C5F248646FDBB2BD7E1139AE6EABA1853F2ABCFDB6C890BDEF5D6CBA55F4498A70942F98DDA49ECEF484CBE5E2DE97175F44F1A184144354C12FFAC100F05F916B21602FE66C29E7985EB3D8FE9E689A81CF9B15CB7D89682E2A63BE1F02566AE653FBFFCADD6A8AF9BFD9E629E4898DA671089D9C3694D2D02FEDE61ADFC6F19A3628E13E118525986456954384ED531D488ECADFFF4EB385BA19F1F01EE6A91A7E5C155ED7A6ADBB0C238A0D59F9B98F2D5AF3454F98A3F36C3F90B64ED85E32B922CE3C4100A663329826D4F9603846202290E07B37084C97A286D15BFDE0840856F3A4D81DB0F5A4D0BE0EC51CE60FFA2E313196C7750E873E0EEE135E1A0E84D9A59A311935036A8068F1525B133A760DB0882ABF3265899C8C718D2ABC71A572293BB27F95EF71025B018B034E554C57491107168EF55A861E5E119AF2E70A5CE0A1BE510779C98E65B67251B5E6865532E93BE8F8A5D458CBE4CBBF171B03DE34FF9190AE55A12AB723D11046E682A565B26C31DBB8A3D6D5A01060D40CD7751B3AE54ABA984052FBCB1B81EA849965C1B99D3EE24B8484084B7F424D32885B2E98B0E01BC9FE1FBAA149F4C84F556B5D1ACEF9AA986FF2DA75BD7DF58ED7B85B9837BAF679651100D4D9A854CE9A72C40656015AC9D488548C1C066ED41D4AEE6565);

CREATE TABLE mariapersist_torrent_scrapes (
    `file_path` VARCHAR(256) NOT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    `metadata` JSON NOT NULL DEFAULT "{}",
    PRIMARY KEY (`file_path`, `created`),
    INDEX (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
ALTER TABLE mariapersist_torrent_scrapes ADD COLUMN `created_date` DATE NOT NULL DEFAULT CURDATE();
ALTER TABLE mariapersist_torrent_scrapes ADD COLUMN `seeders` INT GENERATED ALWAYS AS (JSON_EXTRACT(metadata, "$.scrape.seeders")) PERSISTENT;
ALTER TABLE mariapersist_torrent_scrapes ADD INDEX `created_date_file_path_seeders` (`created_date`, `file_path`, `seeders`);


INSERT INTO `mariapersist_torrent_scrapes` (file_path, created, created_date, metadata) VALUES
('torrents/managed_by_aa/libgenli_comics/aa_lgli_comics_2022_08_files.sql.gz.torrent','2023-07-17 22:52:47','2023-07-17','{"scrape":{"seeders":2,"completed":75,"leechers":1}}');

-- CREATE TABLE mariapersist_searches (
--     `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
--     `search_input` BINARY(100) NOT NULL,
--     PRIMARY KEY (`timestamp`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin PAGE_COMPRESSED=1;

CREATE TABLE mariapersist_slow_download_access (
    `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
    `md5` binary(16) NOT NULL,
    `ip` binary(16) NOT NULL,
    `account_id` char(7) DEFAULT NULL,
    PRIMARY KEY (`timestamp`,`md5`,`ip`),
    KEY `account_id_timestamp` (`account_id`,`timestamp`),
    CONSTRAINT `mariapersist_slow_download_access_account_id` FOREIGN KEY (`account_id`) REFERENCES `mariapersist_accounts` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- INSERT INTO mariapersist_memberships (account_id, membership_tier, membership_expiration) VALUES ('XXXXX', 5, NOW() + INTERVAL 10 YEAR);
CREATE TABLE mariapersist_memberships (
    `membership_id` BIGINT NOT NULL AUTO_INCREMENT,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `account_id` CHAR(7) NOT NULL,
    `membership_tier` CHAR(7) NOT NULL DEFAULT 0,
    `membership_expiration` TIMESTAMP NOT NULL,
    `from_donation_id` CHAR(22) NULL, # NULL for backwards compatibility
    `bonus_downloads` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`membership_id`),
    INDEX (`created`),
    INDEX (`account_id`),
    INDEX (`from_donation_id`),
    CONSTRAINT `mariapersist_memberships_account_id` FOREIGN KEY (`account_id`) REFERENCES `mariapersist_accounts` (`account_id`),
    CONSTRAINT `mariapersist_memberships_from_donation_id` FOREIGN KEY (`from_donation_id`) REFERENCES `mariapersist_donations` (`donation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin SELECT account_id, membership_tier, membership_expiration FROM mariapersist_accounts WHERE membership_expiration IS NOT NULL;
ALTER TABLE mariapersist_memberships ADD COLUMN `bonus_downloads` INT NOT NULL DEFAULT 0;
ALTER TABLE mariapersist_memberships DROP INDEX `from_donation_id`, ADD INDEX `from_donation_id` (`from_donation_id`);
