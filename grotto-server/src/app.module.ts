import { Module } from '@nestjs/common';
import { GrottoController } from './controllers/grotto.controller';
import { EthereumService } from './services/ethereum.service';
require('dotenv').config();

@Module({
  imports: [],
  controllers: [GrottoController],
  providers: [EthereumService],
})
export class AppModule {}
