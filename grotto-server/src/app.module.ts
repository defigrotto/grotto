import { Module } from '@nestjs/common';
import { GrottoController } from './controllers/grotto.controller';
import { EthereumService } from './services/ethereum.service';
import { GrottoService } from './services/grotto.service';
require('dotenv').config();

@Module({
  imports: [],
  controllers: [GrottoController],
  providers: [GrottoService, EthereumService],
})
export class AppModule {}
