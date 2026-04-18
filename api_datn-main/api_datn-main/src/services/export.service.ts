import { PrismaClient } from '@prisma/client';
import * as ExcelJS from 'exceljs';
import PdfPrinter from 'pdfmake';
import { TDocumentDefinitions, Alignment } from 'pdfmake/interfaces';

const prisma = new PrismaClient();

export class ExportService {
    private printer: any;

    constructor() {
        // Standard fonts configuration for pdfmake with Vietnamese support
        const fonts = {
            Roboto: {
                normal: 'node_modules/pdfmake/fonts/Roboto/Roboto-Regular.ttf',
                bold: 'node_modules/pdfmake/fonts/Roboto/Roboto-Medium.ttf',
                italics: 'node_modules/pdfmake/fonts/Roboto/Roboto-Italic.ttf',
                bolditalics: 'node_modules/pdfmake/fonts/Roboto/Roboto-MediumItalic.ttf'
            }
        };
        // @ts-ignore
        this.printer = new (PdfPrinter as any)(fonts);
    }

    /**
     * Generate Excel for Student Practice History
     */
    async generateStudentHistoryExcel(studentId: string): Promise<Buffer> {
        const student = await prisma.user.findUnique({
            where: { id: studentId },
            select: { name: true, username: true }
        });

        const history = await prisma.testAttempt.findMany({
            where: { userId: studentId },
            include: {
                test: { select: { title: true } },
                part: { select: { partName: true } }
            },
            orderBy: { createdAt: 'desc' }
        });

        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('Lịch sử luyện tập');

        // Styles
        const headerStyle: Partial<ExcelJS.Style> = {
            font: { bold: true, color: { argb: 'FFFFFFFF' } },
            fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1E3A8A' } },
            alignment: { horizontal: 'center' }
        };

        // Student Info Header
        worksheet.mergeCells('A1:E1');
        worksheet.getCell('A1').value = `BÁO CÁO LỊCH SỬ LUYỆN TẬP - HỌC VIÊN: ${student?.name || 'N/A'} (${student?.username})`;
        worksheet.getCell('A1').font = { bold: true, size: 14 };
        worksheet.getCell('A1').alignment = { horizontal: 'center' };
        worksheet.addRow([]);

        // Table Header
        const headerRow = worksheet.addRow(['STT', 'Ngày làm', 'Nội dung', 'Số câu đúng', 'Điểm quy đổi']);
        headerRow.eachCell((cell) => {
            cell.style = headerStyle;
        });

        // Data Rows
        history.forEach((attempt, index) => {
            const row = worksheet.addRow([
                index + 1,
                attempt.createdAt.toLocaleDateString('vi-VN'),
                attempt.test?.title || attempt.part?.partName || 'Luyện tập lẻ',
                `${attempt.correctCount}/${attempt.totalQuestions}`,
                attempt.totalScore || 0
            ]);
            row.getCell(1).alignment = { horizontal: 'center' };
            row.getCell(4).alignment = { horizontal: 'center' };
            row.getCell(5).alignment = { horizontal: 'center' };
        });

        // Column Widths
        worksheet.getColumn(1).width = 8;
        worksheet.getColumn(2).width = 15;
        worksheet.getColumn(3).width = 40;
        worksheet.getColumn(4).width = 15;
        worksheet.getColumn(5).width = 15;

        const buffer = await workbook.xlsx.writeBuffer();
        return Buffer.from(buffer);
    }

    /**
     * Generate PDF for Student Practice History & AI Roadmap
     */
    async generateStudentHistoryPdf(studentId: string): Promise<any> {
        const student = await prisma.user.findUnique({
            where: { id: studentId },
            select: { name: true, username: true, targetScore: true, estimatedScore: true }
        });

        const history = await prisma.testAttempt.findMany({
            where: { userId: studentId },
            include: {
                test: { select: { title: true } },
                part: { select: { partName: true } }
            },
            orderBy: { createdAt: 'desc' }
        });

        // Lấy lịch sử lộ trình AI
        const aiAssessments = await prisma.aiAssessment.findMany({
            where: { userId: studentId },
            orderBy: { createdAt: 'desc' },
            take: 15 // Lấy 15 nhận xét gần nhất
        });

        const centerAlign: Alignment = 'center';

        const docDefinition: TDocumentDefinitions = {
            pageSize: 'A4',
            pageMargins: [40, 60, 40, 60],
            content: [
                // Header
                { text: 'ANTIGRAVITY TOEIC LEARNING SYSTEM', style: 'brand', alignment: centerAlign },
                { canvas: [{ type: 'line', x1: 0, y1: 5, x2: 515, y2: 5, lineWidth: 1, lineColor: '#1E3A8A' }] },
                { text: 'BÁO CÁO TỔNG HỢP NĂNG LỰC & LỘ TRÌNH CÁ NHÂN', style: 'pdfTitle', alignment: centerAlign, margin: [0, 20, 0, 20] },
                
                // Student Info Info
                {
                    style: 'infoSection',
                    table: {
                        widths: ['*', '*'],
                        body: [
                            [
                                { text: `Họ và tên: ${student?.name || 'N/A'}`, bold: true },
                                { text: `Mã học viên: ${student?.username || 'N/A'}`, bold: true }
                            ],
                            [
                                { text: `Mục tiêu: ${student?.targetScore || 0} điểm`, color: '#1E3A8A', bold: true },
                                { text: `Điểm tổng hiện tại: ${student?.estimatedScore || 0} / 990`, color: '#059669', bold: true }
                            ]
                        ]
                    },
                    layout: 'noBorders'
                },

                // Section I: Practice history
                { text: 'I. BẢNG ĐIỂM CHI TIẾT LỊCH SỬ LUYỆN TẬP', style: 'sectionHeader' },
                {
                    table: {
                        headerRows: 1,
                        widths: [25, 75, '*', 70, 60],
                        body: [
                            [
                                { text: 'STT', style: 'tableHeader' },
                                { text: 'Ngày làm', style: 'tableHeader' },
                                { text: 'Nội dung bài làm', style: 'tableHeader' },
                                { text: 'Kết quả', style: 'tableHeader' },
                                { text: 'Điểm', style: 'tableHeader' }
                            ],
                            ...history.map((a, i) => [
                                { text: (i + 1).toString(), alignment: centerAlign, fontSize: 10 },
                                { text: a.createdAt.toLocaleDateString('vi-VN'), fontSize: 10 },
                                { text: a.test?.title || a.part?.partName || 'Luyện tập lẻ', fontSize: 10 },
                                { text: `${a.correctCount}/${a.totalQuestions}`, alignment: centerAlign, fontSize: 10 },
                                { text: (a.totalScore || 0).toString(), alignment: centerAlign, bold: true, color: '#1E3A8A', fontSize: 10 }
                            ])
                        ]
                    },
                    layout: {
                        fillColor: function (rowIndex) {
                            return (rowIndex % 2 === 0 && rowIndex !== 0) ? '#F9FAFB' : null;
                        },
                        hLineColor: () => '#E5E7EB',
                        vLineColor: () => '#E5E7EB'
                    }
                },

                // Section II: AI Roadmap
                { text: 'II. LỘ TRÌNH PHÁT TRIỂN NĂNG LỰC CÁ NHÂN HÓA (AI COACHING)', style: 'sectionHeader', margin: [0, 30, 0, 10] },
                aiAssessments.length === 0 
                  ? { text: 'Chưa có phân tích lộ trình AI cho học viên này.', italics: true, color: '#6B7280' }
                  : aiAssessments.map(item => ({
                      stack: [
                        {
                            columns: [
                                { text: item.title, bold: true, fontSize: 12, color: '#1E3A8A' },
                                { text: item.createdAt.toLocaleDateString('vi-VN'), alignment: 'right', fontSize: 10, color: '#6B7280' }
                            ]
                        },
                        { 
                            text: item.summary.replace(/<[^>]*>/g, ''), 
                            fontSize: 10, 
                            margin: [0, 5, 0, 15],
                            lineHeight: 1.3
                        },
                        { canvas: [{ type: 'line', x1: 0, y1: 0, x2: 515, y2: 0, lineWidth: 0.5, lineColor: '#F3F4F6' }] }
                      ],
                      margin: [0, 5, 0, 10]
                    })),

                // Footer
                { 
                    text: '\n\nBáo cáo này được tạo tự động bởi Hệ thống Antigravity Center.\nChúc bạn luyện thi TOEIC hiệu quả và sớm đạt mục tiêu!', 
                    alignment: centerAlign, 
                    fontSize: 9, 
                    color: '#9CA3AF',
                    italics: true
                }
            ],
            styles: {
                brand: { fontSize: 10, bold: true, color: '#1E3A8A', characterSpacing: 1 },
                pdfTitle: { fontSize: 18, bold: true, color: '#111827' },
                sectionHeader: { fontSize: 14, bold: true, color: '#1E3A8A', margin: [0, 25, 0, 10] },
                infoSection: { margin: [0, 0, 0, 20] },
                tableHeader: { bold: true, fontSize: 11, color: 'white', fillColor: '#1E3A8A', alignment: centerAlign, margin: [0, 5, 0, 5] }
            },
            defaultStyle: {
                font: 'Roboto',
                lineHeight: 1.2
            }
        };

        return this.printer.createPdfKitDocument(docDefinition);
    }

    /**
     * Generate PDF for a Single Specific AiAssessment (Roadmap)
     */
    async generateSingleRoadmapPdf(assessmentId: string): Promise<any> {
        const assessment = await (prisma as any).aiAssessment.findUnique({
            where: { id: assessmentId },
            include: { user: { select: { name: true, username: true, targetScore: true, estimatedScore: true } } }
        });

        if (!assessment) throw new Error('Không tìm thấy lộ trình');

        const centerAlign: Alignment = 'center';

        const docDefinition: TDocumentDefinitions = {
            pageSize: 'A4',
            pageMargins: [40, 60, 40, 60],
            content: [
                { text: 'ANTIGRAVITY TOEIC LEARNING SYSTEM', style: 'brand', alignment: centerAlign },
                { canvas: [{ type: 'line' as any, x1: 0, y1: 5, x2: 515, y2: 5, lineWidth: 1, lineColor: '#1E3A8A' }] },
                
                { text: 'LỘ TRÌNH PHÁT TRIỂN NĂNG LỰC CÁ NHÂN HÓA', style: 'pdfTitle', alignment: centerAlign, margin: [0, 25, 0, 10] },
                { text: `Ngày tạo: ${assessment.createdAt.toLocaleDateString('vi-VN')}`, alignment: centerAlign, fontSize: 10, color: '#6B7280', margin: [0, 0, 0, 20] },

                // Student Stats Info
                {
                    style: 'infoSection',
                    table: {
                        widths: ['*', '*'],
                        body: [
                            [
                                { text: `Học viên: ${assessment.user?.name || 'N/A'}`, bold: true },
                                { text: `Mã số: ${assessment.user?.username || 'N/A'}`, bold: true }
                            ],
                            [
                                { text: `Mục tiêu: ${assessment.user?.targetScore || 0} điểm`, color: '#1E3A8A', bold: true },
                                { text: `Dự kiến hiện tại: ${assessment.user?.estimatedScore || 0} / 990`, color: '#059669', bold: true }
                            ]
                        ]
                    },
                    layout: 'noBorders'
                },

                // I. Overview Summary
                { text: 'I. TỔNG QUAN NĂNG LỰC HIỆN TẠI', style: 'sectionHeader' },
                { 
                    text: assessment.summary.replace(/<[^>]*>/g, ''), 
                    fontSize: 11, 
                    lineHeight: 1.5,
                    margin: [5, 0, 0, 10] as [number, number, number, number]
                },

                // II. Teacher's Note (Mục tiêu của User) - Supports HTML to plain conversion Lite
                ...(assessment.teacherNote ? [
                    { text: 'II. LỜI KHUYÊN TỪ GIÁO VIÊN', style: 'sectionHeader' },
                    { 
                        canvas: [{ type: 'rect' as any, x: 0, y: 0, w: 515, h: 2, color: '#1E3A8A' }] 
                    },
                    { 
                        text: assessment.teacherNote.replace(/<[^>]*>/g, '\n').trim(), 
                        fontSize: 11, 
                        italics: true,
                        color: '#1E3A8A',
                        margin: [10, 10, 10, 20] as [number, number, number, number],
                        lineHeight: 1.4
                    }
                ] : []),

                // III. Phân tích chi tiết (từ field content)
                { text: 'III. CHI TIẾT LỘ TRÌNH & KỸ NĂNG', style: 'sectionHeader' },
                {
                    stack: [
                        { text: 'Phân tích dựa trên 10 bài luyện tập gần nhất và xu hướng phát triển của AI Coaching.', fontSize: 10, italics: true, color: '#6B7280', margin: [0, 0, 0, 15] },
                        // Rendering details from roadmap content if available
                        ...(assessment.content && (assessment.content as any).recommendations ? (assessment.content as any).recommendations.map((rec: string) => ({
                            text: `• ${rec}`, margin: [0, 2, 0, 5] as any, fontSize: 10
                        })) : [{ text: 'Chi tiết lộ trình được tối ưu hóa trong ứng dụng di động.', fontSize: 10 }])
                    ]
                },

                // Footer
                { 
                    text: '\n\n\n\nBáo cáo này được bảo mật và chỉ dành riêng cho mục đích học tập cá nhân.\n© 2024 Antigravity Center - Empower your potential.', 
                    alignment: centerAlign, 
                    fontSize: 8, 
                    color: '#9CA3AF',
                    italics: true,
                    margin: [0, 50, 0, 0] as [number, number, number, number]
                }
            ],
            styles: {
                brand: { fontSize: 11, bold: true, color: '#1E3A8A', characterSpacing: 1.2 },
                pdfTitle: { fontSize: 20, bold: true, color: '#111827' },
                sectionHeader: { fontSize: 15, bold: true, color: '#1E3A8A', margin: [0, 20, 0, 10], decoration: 'underline' },
                infoSection: { margin: [0, 10, 0, 20], fillColor: '#F3F4F6' },
                tableHeader: { bold: true, fontSize: 12, color: 'white', fillColor: '#1E3A8A', alignment: centerAlign }
            },
            defaultStyle: {
                font: 'Roboto',
                lineHeight: 1.2
            }
        };

        return this.printer.createPdfKitDocument(docDefinition);
    }
}
