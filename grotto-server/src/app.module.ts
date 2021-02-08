import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { GrottoController } from './controllers/grotto.controller';

@Module({
  imports: [],
  controllers: [AppController, GrottoController],
  providers: [AppService],
})
export class AppModule {}
